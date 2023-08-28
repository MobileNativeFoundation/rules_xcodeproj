"""Module containing functions dealing with target input files."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
    "AppleResourceInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo", "SwiftProtoInfo")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(
    ":files.bzl",
    "FRAMEWORK_EXTENSIONS",
    "RESOURCES_FOLDER_TYPE_EXTENSIONS",
    "normalized_file_path",
)
load(":indexstore_filelists.bzl", "indexstore_filelists")
load(":linker_input_files.bzl", "linker_input_files")
load(
    ":memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_DICT",
    "EMPTY_LIST",
    "EMPTY_STRING",
    "memory_efficient_depset",
)
load(":output_files.bzl", "parse_swift_info_module", "swift_to_outputs")
load(":providers.bzl", "XcodeProjInfo")
load(":resources.bzl", "collect_resources")
load(":target_properties.bzl", "should_include_non_xcode_outputs")

# Utility

def _collect_transitive_uncategorized(info):
    if info.xcode_target:
        return EMPTY_DEPSET
    return info.inputs.uncategorized

_IGNORE_ATTR = {
    "to_json": None,
    "to_proto": None,
}

def _should_ignore_input_attr(attr):
    return (
        # We don't want to include implicit dependencies
        attr[0] == "_" or
        # These are actually Starklark methods, so ignore them
        attr in _IGNORE_ATTR
    )

def _process_cc_info_headers(headers, *, exclude_headers, generated):
    def _process_header(header):
        exclude_headers[header] = None
        if not header.is_source:
            generated.append(header)
        return normalized_file_path(
            header,
            folder_type_extensions = FRAMEWORK_EXTENSIONS,
        )

    return [
        _process_header(header)
        for header in headers
        if header not in exclude_headers
    ]

def _transform_into_label_to_resources(resources):
    """Helper function to transform resources for easier consumption

    Args:
        resources: A `list` of tuples (`owner`, `file_path`) of resources that should be
            added to the target's bundle.

    Returns:
        A `list` of tuples (`owner`, depset([`resource`]))
    """
    label_to_resources_depset = {}
    for (owner, resource) in resources:
        label_to_resources_depset.setdefault(owner, {})[resource] = None
    return [
        (owner, depset(resources.keys()))
        for owner, resources in label_to_resources_depset.items()
    ]

# API

C_EXTENSIONS = {
    "c": None,
    "m": None,
}

CXX_EXTENSIONS = {
    "C": None,
    "c++": None,
    "cc": None,
    "cl": None,
    "cpp": None,
    "cu": None,
    "cxx": None,
    "mm": None,
}

def _collect_input_files(
        *,
        ctx,
        target,
        attrs,
        unfocused = False,
        id,
        platform,
        is_bundle,
        product,
        linker_inputs,
        automatic_target_info,
        additional_files = EMPTY_LIST,
        modulemaps = None,
        transitive_infos,
        avoid_deps = EMPTY_LIST):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        target: The `Target` to collect inputs from.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        unfocused: Whether the target is unfocused. If `None`, it will be
            determined automatically (this should only be the case for
            `non_xcode_target`s).
        id: A unique identifier for the target. Will be `None` for non-Xcode
            targets.
        platform: A value returned from `platforms.collect`.
        is_bundle: Whether `target` is a bundle.
        product: A value returned from `process_product`.
        linker_inputs: A value returned from `linker_file_inputs.collect`.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        additional_files: A `list` of `File`s to add to the inputs. This can
            be used to add files to the `generated` and `extra_files` fields
            (e.g. modulemaps or BUILD files).
        modulemaps: A `depset` of `File`s that are modulemap dependencies for
            `target`, or `None`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of `target`.
        avoid_deps: A `list` of the targets that already consumed resources, and
            their resources shouldn't be bundled with `target`.

    Returns:
        A `tuple` with two elements:

        *   A `struct`, which will only be used within the aspect, with the
            following fields:

            *   `generated`: A `depset` of generated `File`s that are inputs to
                `target` or its transitive dependencies.
            *   `hdrs`: A `list` of `File`s that are inputs to `target`'s
                `hdrs`-like attributes.
            *   `non_arc_srcs`: A `list` of `File`s that are inputs to
                `target`'s `non_arc_srcs`-like attributes.
            *   `resources`: A `depset` of `FilePath`s that are inputs to
                `target`'s `resources`-like and `structured_resources`-like
                attributes.
            *   `srcs`: A `list` of `File`s that are inputs to `target`'s
                `srcs`-like attributes.

        *   A `struct`, which will end up in `XcodeProjInfo.inputs`, with the
            following fields:

            *   `xccurrentversions`: A `depset` of `.xccurrentversion` `File`s
                that are in `resources`.
            *   `generated`: A `depset` of generated `File`s that are inputs to
                `target` or its transitive dependencies.
            *   `important_generated`: A `depset` of important generated `File`s
                that are inputs to `target` or its transitive dependencies.
                These differ from `generated` in that they will be generated as
                part of project generation, to ensure they are created before
                Xcode is opened. Entitlements are an example of this, as Xcode
                won't even start a build if they are missing.
            *   `extra_files`: A `depset` of `FilePath`s that should be included
                in the project, but aren't necessarily inputs to the target.
                This also includes some categorized files of transitive
                dependencies that didn't create an Xcode target.
            *   `uncategorized`: A `depset` of `FilePath`s that are inputs to
                `target` didn't fall into one of the more specific (e.g. `srcs`)
                categories. These will only be included in the Xcode project if
                this target becomes an input to another target's categorized
                attribute.
    """
    entitlements = []
    c_sources = {}
    cxx_sources = {}
    hdrs = []
    non_arc_srcs = []
    pch = []
    srcs = []
    uncategorized = []

    generated = [file for file in additional_files if not file.is_source]
    extra_files = [file.path for file in additional_files]

    label = target.label

    # Include BUILD files for the project but not for external repos
    if not label.workspace_root:
        extra_files.append(ctx.build_file_path)

    # buildifier: disable=uninitialized
    def _handle_srcs_file(file):
        srcs.append(file)
        extension = file.extension
        if extension in C_EXTENSIONS:
            c_sources[file.path] = None
        elif extension in CXX_EXTENSIONS:
            cxx_sources[file.path] = None

    # buildifier: disable=uninitialized
    def _handle_non_arc_srcs_file(file):
        non_arc_srcs.append(file)
        extension = file.extension
        if extension in C_EXTENSIONS:
            c_sources[file.path] = None
        elif extension in CXX_EXTENSIONS:
            cxx_sources[file.path] = None

    # buildifier: disable=uninitialized
    def _handle_hdrs_file(file):
        hdrs.append(file)

    # buildifier: disable=uninitialized
    def _handle_pch_file(file):
        # We use `append` instead of setting a single value because
        # assigning to `pch` creates a new local variable instead of
        # assigning to the existing variable
        pch.append(file)
        extra_files.append(file.path)

    # buildifier: disable=uninitialized
    def _handle_entitlements_file(file):
        # We use `append` instead of setting a single value because
        # assigning to `entitlements` creates a new local variable instead
        # of assigning to the existing variable
        entitlements.append(file)
        extra_files.append(file.path)

    # buildifier: disable=uninitialized
    def _handle_extrafiles_file(file):
        extra_files.append(file.path)

    file_handlers = {}

    if id:
        for attr in automatic_target_info.srcs:
            file_handlers[attr] = _handle_srcs_file
        for attr in automatic_target_info.non_arc_srcs:
            file_handlers[attr] = _handle_non_arc_srcs_file
        for attr in automatic_target_info.hdrs:
            file_handlers[attr] = _handle_hdrs_file
    else:
        # Turn source files into extra files for unsupported targets
        for attr in automatic_target_info.srcs:
            file_handlers[attr] = _handle_extrafiles_file
        for attr in automatic_target_info.non_arc_srcs:
            file_handlers[attr] = _handle_extrafiles_file
        for attr in automatic_target_info.hdrs:
            file_handlers[attr] = _handle_extrafiles_file

    if automatic_target_info.pch:
        file_handlers[automatic_target_info.pch] = _handle_pch_file
    for attr in automatic_target_info.infoplists:
        file_handlers[attr] = _handle_extrafiles_file
    for attr in automatic_target_info.launchdplists:
        file_handlers[attr] = _handle_extrafiles_file
    if automatic_target_info.alternate_icons:
        file_handlers[automatic_target_info.alternate_icons] = (
            _handle_extrafiles_file
        )
    if automatic_target_info.entitlements:
        file_handlers[automatic_target_info.entitlements] = (
            _handle_entitlements_file
        )
    for attr in automatic_target_info.exported_symbols_lists:
        file_handlers[attr] = _handle_extrafiles_file

    categorized_files = {}
    xccurrentversions = []

    # buildifier: disable=uninitialized
    def _handle_file(file, *, handler):
        if file == None:
            return

        if handler:
            handler(file)
            categorized = True
            categorized_files[file] = None
        else:
            categorized = False

        if file.is_source:
            if not categorized:
                if (file.basename == ".xccurrentversion" and
                    file.dirname.endswith(".xcdatamodeld")):
                    # rules_ios's `precompiled_apple_resource_bundle` rule
                    # exposes its resources as inputs, so we have to have the
                    # same check here for the `.xccurrentversion` file as we
                    # do in `resources.bzl`
                    xccurrentversions.append(file)
                else:
                    uncategorized.append(
                        normalized_file_path(
                            file,
                            folder_type_extensions = (
                                RESOURCES_FOLDER_TYPE_EXTENSIONS
                            ),
                        ),
                    )
        elif categorized:
            generated.append(file)

    transitive_extra_files = []

    # buildifier: disable=uninitialized
    def _handle_dep(dep):
        # This allows the transitive uncategorized files for target of a
        # categorized attribute to be included in the project
        if XcodeProjInfo not in dep:
            return
        transitive_extra_files.append(dep[XcodeProjInfo].inputs.uncategorized)

    collect_uncategorized_files = (
        automatic_target_info.collect_uncategorized_files
    )

    for attr in dir(ctx.rule.files):
        if _should_ignore_input_attr(attr):
            continue

        handler = file_handlers.get(attr, None)

        if not collect_uncategorized_files and not handler:
            continue

        for file in getattr(ctx.rule.files, attr):
            _handle_file(file, handler = handler)

    for attr in dir(ctx.rule.file):
        if _should_ignore_input_attr(attr):
            continue

        handler = file_handlers.get(attr, None)

        if not collect_uncategorized_files and not handler:
            continue

        _handle_file(getattr(ctx.rule.file, attr), handler = handler)

    if SwiftProtoInfo in target:
        for file in target[SwiftProtoInfo].pbswift_files.to_list():
            _handle_file(file, handler = _handle_srcs_file)

    for attr in attrs:
        if _should_ignore_input_attr(attr):
            continue

        if attr not in file_handlers:
            # Only attributes in `file_handlers` are categorized
            continue

        dep = getattr(ctx.rule.attr, attr)

        dep_type = type(dep)
        if dep_type == "Target":
            _handle_dep(dep)
        elif dep_type == "list":
            if not dep or type(dep[0]) != "Target":
                continue
            for list_dep in dep:
                _handle_dep(list_dep)

    product_framework_files = memory_efficient_depset(
        transitive = [
            info.inputs._product_framework_files
            for info in transitive_infos
        ] + ([product.framework_files] if product else []),
    )

    linker_input_additional_files = linker_input_files.to_input_files(
        linker_inputs,
    )
    if linker_input_additional_files:
        framework_files = {f: None for f in product_framework_files.to_list()}
        linker_input_additional_files = [
            file
            for file in linker_input_additional_files
            if file not in framework_files
        ]
        generated.extend([
            file
            for file in linker_input_additional_files
            if not file.is_source
        ])
        for file in linker_input_additional_files:
            extra_files.append(
                normalized_file_path(
                    file,
                    folder_type_extensions = FRAMEWORK_EXTENSIONS,
                ),
            )

    is_resource_bundle_consuming = is_bundle and AppleResourceInfo in target

    resources = None
    folder_resources = None
    resource_bundles = None
    resource_bundle_dependencies = None
    if is_resource_bundle_consuming:
        resources_result = collect_resources(
            platform = platform,
            resource_info = target[AppleResourceInfo],
            avoid_resource_infos = [
                dep[AppleResourceInfo]
                for dep in avoid_deps
                if AppleResourceInfo in dep
            ],
        )

        generated.extend(resources_result.generated)
        xccurrentversions.extend(resources_result.xccurrentversions)

        bundle_labels_list = [
            bundle.label
            for bundle in resources_result.bundles
        ]
        resource_bundle_labels = memory_efficient_depset(
            bundle_labels_list,
            transitive = [
                dep[XcodeProjInfo].inputs._resource_bundle_labels
                for dep in avoid_deps
            ],
        )
        bundle_labels = {
            label: None
            for label in resource_bundle_labels.to_list()
        }

        transitive_extra_files.extend([
            depset([(label, d)])
            for label, d in depset(
                transitive = [
                    info.inputs._resource_bundle_uncategorized
                    for info in transitive_infos
                ],
            ).to_list()
            if label not in bundle_labels
        ])

        extra_files.extend(resources_result.extra_files)
        resource_bundles = resources_result.bundles
        if resources_result.dependencies:
            resource_bundle_dependencies = resources_result.dependencies
        if resources_result.resources:
            resources = depset(
                _transform_into_label_to_resources(resources_result.resources),
            )
        if resources_result.folder_resources:
            folder_resources = depset(
                _transform_into_label_to_resources(
                    resources_result.folder_resources,
                ),
            )
    else:
        resource_bundle_labels = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_labels
                for info in transitive_infos
            ],
        )

    is_bwx = ctx.attr._build_mode == "xcode"

    # Generically handle CcInfo providing rules. This allows us to pick up
    # headers from `objc_import` and the like.
    if is_bwx and SwiftInfo in target:
        swift_info = target[SwiftInfo]
        for module in swift_info.direct_modules:
            clang = module.clang
            if not clang:
                continue
            for header in clang.compilation_context.direct_public_headers:
                # Exclude Swift generated header, because we don't use it in
                # BwX mode
                categorized_files[header] = None
    if CcInfo in target:
        compilation_context = target[CcInfo].compilation_context
        extra_files.extend(_process_cc_info_headers(
            (compilation_context.direct_private_headers +
             compilation_context.direct_public_headers +
             compilation_context.direct_textual_headers),
            exclude_headers = categorized_files,
            generated = generated,
        ))

    should_produce_output_groups = is_bwx

    # Collect unfocused target info
    indexstores = []
    indexstore_overrides = []
    bwx_unfocused_libraries = None
    if should_include_non_xcode_outputs(ctx = ctx):
        if unfocused == None:
            (dep_compilation_providers, _) = comp_providers.merge(
                transitive_compilation_providers = [
                    (info.xcode_target, info.compilation_providers)
                    for info in transitive_infos
                ],
            )
            (
                direct_libraries,
                transitive_libraries,
            ) = linker_input_files.get_library_static_libraries_for_bwx(
                linker_inputs = linker_inputs,
                dep_compilation_providers = dep_compilation_providers,
            )

            unfocused_generated_linking = transitive_libraries

            unfocused = bool(direct_libraries)
            if unfocused:
                generated.extend(transitive_libraries)
                bwx_unfocused_libraries = memory_efficient_depset(
                    [
                        file.path
                        for file in transitive_libraries
                    ],
                )
        else:
            unfocused_generated_linking = (
                linker_input_files.get_transitive_static_libraries_for_bwx(
                    linker_inputs = linker_inputs,
                )
            )

        if unfocused_generated_linking:
            unfocused_generated_linking = tuple(unfocused_generated_linking)
        else:
            unfocused_generated_linking = None

        is_swift = SwiftInfo in target

        if unfocused and is_swift:
            non_target_swift_info_modules = target[SwiftInfo].transitive_modules
        else:
            non_target_swift_info_modules = memory_efficient_depset(
                transitive = [
                    info.inputs._non_target_swift_info_modules
                    for info in transitive_infos
                ],
            )
        for module in non_target_swift_info_modules.to_list():
            swiftmodules, indexstore = swift_to_outputs(
                parse_swift_info_module(module),
            )
            generated.extend(swiftmodules)
            if should_produce_output_groups and indexstore:
                indexstore_overrides.append((indexstore, EMPTY_STRING))
                indexstores.append(indexstore)

        if is_swift:
            unfocused_swift_info_modules = target[SwiftInfo].transitive_modules
        else:
            unfocused_swift_info_modules = non_target_swift_info_modules

        unfocused_generated_compiling = []
        unfocused_generated_indexstores = []
        for module in unfocused_swift_info_modules.to_list():
            swiftmodules, indexstore = swift_to_outputs(
                parse_swift_info_module(module),
            )

            unfocused_generated_compiling.extend(swiftmodules)
            if indexstore:
                unfocused_generated_indexstores.append(indexstore)

        if unfocused_generated_compiling:
            unfocused_generated_compiling = tuple(unfocused_generated_compiling)
        else:
            unfocused_generated_compiling = None
        if unfocused_generated_indexstores:
            unfocused_generated_indexstores = tuple(
                unfocused_generated_indexstores,
            )
        else:
            unfocused_generated_indexstores = None
    else:
        non_target_swift_info_modules = EMPTY_DEPSET
        unfocused_generated_compiling = None
        unfocused_generated_indexstores = None
        unfocused_generated_linking = None

        # Set non-`None` to prevent hitting the
        # `if not bwx_unfocused_libraries:` check and subsequent calculation
        # below
        bwx_unfocused_libraries = EMPTY_DEPSET

    important_generated = [
        file
        for file in entitlements
        if not file.is_source
    ]

    generated_depset = memory_efficient_depset(
        generated,
        transitive = [
            info.inputs.generated
            for info in transitive_infos
        ],
    )

    if should_produce_output_groups:
        transitive_indexstore_overrides = memory_efficient_depset(
            indexstore_overrides,
            transitive = [
                info.inputs._indexstore_overrides
                for info in transitive_infos
            ],
        )
        transitive_indexstores = memory_efficient_depset(
            indexstores,
            transitive = [
                info.inputs._indexstores
                for info in transitive_infos
            ],
        )
    else:
        transitive_indexstore_overrides = EMPTY_DEPSET
        transitive_indexstores = EMPTY_DEPSET

    # We need to collect transitive modulemaps, because some are private to
    # dependent targets, but we still need them for the final output group
    modulemaps_depset = memory_efficient_depset(
        [f for f in modulemaps if not f.is_source] if modulemaps else None,
        transitive = [
            info.inputs._modulemaps
            for info in transitive_infos
        ],
    )

    # Purposeful flattening to work around large BEP issue.
    # This is because we only get modulemaps already flattened. Ideally we
    # would get a `depset` for the modulemaps, so they would be properly
    # represented in the BEP.
    modulemaps = modulemaps_depset.to_list()

    if id:
        compiling_files = memory_efficient_depset(
            modulemaps,
            transitive = [generated_depset],
        )
    else:
        compiling_files = generated_depset

    if id and should_produce_output_groups:
        compiling_output_group_name = "xc {}".format(id)
        indexstores_output_group_name = "xi {}".format(id)
        linking_output_group_name = "xl {}".format(id)

        indexstores_filelist = indexstore_filelists.write(
            actions = ctx.actions,
            indexstore_and_target_overrides = transitive_indexstore_overrides,
            indexstores = transitive_indexstores,
            name = "xi",
            rule_name = ctx.rule.attr.name,
        )

        # We don't want to declare indexstore files as outputs, because they
        # expand to individual files and blow up the BEP
        indexstores_files = depset([indexstores_filelist])

        direct_group_list = [
            (compiling_output_group_name, False, compiling_files),
            (indexstores_output_group_name, True, indexstores_files),
            (linking_output_group_name, False, EMPTY_DEPSET),
        ]
    else:
        compiling_output_group_name = None
        indexstores_output_group_name = None
        linking_output_group_name = None
        direct_group_list = None

    if not bwx_unfocused_libraries:
        bwx_unfocused_libraries = memory_efficient_depset(
            transitive = [
                info.inputs.bwx_unfocused_libraries
                for info in transitive_infos
            ],
        )

    if is_resource_bundle_consuming:
        # We've consumed them above
        resource_bundle_uncategorized = EMPTY_DEPSET
    else:
        if (AppleResourceBundleInfo in target and
            automatic_target_info.bundle_id):
            resource_bundle_uncategorized = uncategorized
            uncategorized = None
        else:
            resource_bundle_uncategorized = None

        if resource_bundle_uncategorized:
            resource_bundle_uncategorized_direct = [
                (
                    label,
                    memory_efficient_depset(resource_bundle_uncategorized),
                ),
            ]
        else:
            resource_bundle_uncategorized_direct = None

        resource_bundle_uncategorized = memory_efficient_depset(
            resource_bundle_uncategorized_direct,
            transitive = [
                info.inputs._resource_bundle_uncategorized
                for info in transitive_infos
            ],
        )

    has_generated_files = bool(generated)
    if not has_generated_files:
        for info in transitive_infos:
            if info.inputs.has_generated_files:
                has_generated_files = True
                break

    return (
        struct(
            compiling_files = compiling_files,
            compiling_output_group_name = compiling_output_group_name,
            entitlements = entitlements[0] if entitlements else None,
            folder_resources = folder_resources,
            generated = generated_depset,
            c_sources = c_sources,
            cxx_sources = cxx_sources,
            hdrs = hdrs,
            indexstores = transitive_indexstores,
            indexstores_output_group_name = indexstores_output_group_name,
            linking_output_group_name = linking_output_group_name,
            non_arc_srcs = non_arc_srcs,
            pch = pch[0] if pch else None,
            resource_bundle_dependencies = memory_efficient_depset(
                resource_bundle_dependencies,
            ),
            resources = resources,
            srcs = srcs,
            unfocused_generated_compiling = unfocused_generated_compiling,
            unfocused_generated_indexstores = unfocused_generated_indexstores,
            unfocused_generated_linking = unfocused_generated_linking,
        ),
        struct(
            _indexstore_overrides = transitive_indexstore_overrides,
            _indexstores = transitive_indexstores,
            _modulemaps = modulemaps_depset,
            _non_target_swift_info_modules = non_target_swift_info_modules,
            _output_group_list = memory_efficient_depset(
                direct_group_list,
                transitive = [
                    info.inputs._output_group_list
                    for info in transitive_infos
                ],
            ) if should_produce_output_groups else EMPTY_DEPSET,
            _product_framework_files = product_framework_files,
            _resource_bundle_labels = resource_bundle_labels,
            _resource_bundle_uncategorized = resource_bundle_uncategorized,
            resource_bundles = memory_efficient_depset(
                resource_bundles,
                transitive = [
                    info.inputs.resource_bundles
                    for info in transitive_infos
                ],
            ),
            xccurrentversions = memory_efficient_depset(
                [(label, tuple(xccurrentversions))] if xccurrentversions else None,
                transitive = [
                    info.inputs.xccurrentversions
                    for info in transitive_infos
                ],
            ),
            generated = generated_depset,
            important_generated = memory_efficient_depset(
                important_generated,
                transitive = [
                    info.inputs.important_generated
                    for info in transitive_infos
                ],
            ),
            has_generated_files = has_generated_files,
            extra_files = memory_efficient_depset(
                [(label, depset(extra_files))] if extra_files else None,
                transitive = [
                    depset(transitive = [info.inputs.extra_files])
                    for info in transitive_infos
                ] + transitive_extra_files,
            ),
            uncategorized = memory_efficient_depset(
                [(label, depset(uncategorized))] if uncategorized else None,
                transitive = [
                    _collect_transitive_uncategorized(info)
                    for info in transitive_infos
                ],
            ),
            bwx_unfocused_libraries = bwx_unfocused_libraries,
        ),
    )

def _from_resource_bundle(bundle):
    return struct(
        compiling_output_group_name = None,
        entitlements = None,
        folder_resources = depset(
            _transform_into_label_to_resources(bundle.folder_resources),
        ),
        generated = EMPTY_DEPSET,
        c_sources = EMPTY_DICT,
        cxx_sources = EMPTY_DICT,
        hdrs = EMPTY_LIST,
        indexstores = EMPTY_DEPSET,
        indexstores_output_group_name = None,
        linking_output_group_name = None,
        non_arc_srcs = EMPTY_LIST,
        pch = None,
        resource_bundle_dependencies = bundle.dependencies,
        resources = depset(
            _transform_into_label_to_resources(bundle.resources),
        ),
        srcs = EMPTY_LIST,
        unfocused_generated_compiling = None,
        unfocused_generated_indexstores = None,
        unfocused_generated_linking = None,
    )

def _merge_input_files(*, transitive_infos, extra_generated = None):
    """Creates merged inputs.

    Args:
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.
        extra_generated: An optional `list` of `File`s to added to `generated`.

    Returns:
        A value similar to the one returned from `input_files.collect`. The
        values potentially include the inputs of the transitive dependencies,
        via `transitive_infos` (e.g. `generated` and `extra_files`).
    """
    has_generated_files = False
    for info in transitive_infos:
        if info.inputs.has_generated_files:
            has_generated_files = True
            break

    return struct(
        _indexstore_overrides = memory_efficient_depset(
            transitive = [
                info.inputs._indexstore_overrides
                for info in transitive_infos
            ],
        ),
        _indexstores = memory_efficient_depset(
            transitive = [
                info.inputs._indexstores
                for info in transitive_infos
            ],
        ),
        _modulemaps = memory_efficient_depset(
            transitive = [
                info.inputs._modulemaps
                for info in transitive_infos
            ],
        ),
        _non_target_swift_info_modules = memory_efficient_depset(
            transitive = [
                info.inputs._non_target_swift_info_modules
                for info in transitive_infos
            ],
        ),
        _output_group_list = memory_efficient_depset(
            transitive = [
                info.inputs._output_group_list
                for info in transitive_infos
            ],
        ),
        _product_framework_files = memory_efficient_depset(
            transitive = [
                info.inputs._product_framework_files
                for info in transitive_infos
            ],
        ),
        _resource_bundle_labels = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_labels
                for info in transitive_infos
            ],
        ),
        _resource_bundle_uncategorized = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_uncategorized
                for info in transitive_infos
            ],
        ),
        resource_bundles = memory_efficient_depset(
            transitive = [
                info.inputs.resource_bundles
                for info in transitive_infos
            ],
        ),
        xccurrentversions = memory_efficient_depset(
            transitive = [
                info.inputs.xccurrentversions
                for info in transitive_infos
            ],
        ),
        generated = memory_efficient_depset(
            extra_generated,
            transitive = [
                info.inputs.generated
                for info in transitive_infos
            ],
        ),
        important_generated = memory_efficient_depset(
            transitive = [
                info.inputs.important_generated
                for info in transitive_infos
            ],
        ),
        has_generated_files = has_generated_files,
        extra_files = memory_efficient_depset(
            transitive = [
                info.inputs.extra_files
                for info in transitive_infos
            ],
        ),
        uncategorized = memory_efficient_depset(
            transitive = [
                info.inputs.uncategorized
                for info in transitive_infos
            ],
        ),
        bwx_unfocused_libraries = memory_efficient_depset(
            transitive = [
                info.inputs.bwx_unfocused_libraries
                for info in transitive_infos
            ],
        ),
    )

def _process_output_group_files(
        *,
        files,
        is_indexstores,
        output_group_name,
        additional_bwx_generated,
        index_import):
    # `list` copy is needed for some reason to prevent depset from changing
    # underneath us. Without this it's nondeterministic which files are in it.
    generated_depsets = list(
        additional_bwx_generated.get(output_group_name, []),
    )

    if is_indexstores:
        direct = [index_import]
    else:
        direct = None

    return memory_efficient_depset(
        direct,
        transitive = generated_depsets + [files],
    )

def _to_output_groups_fields(
        *,
        inputs,
        additional_bwx_generated = {},
        index_import):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        inputs: A value returned from `input_files.collect`.
        additional_bwx_generated: A `dict` that maps the output group name of
            targets to a `list` of `depset`s of `File`s that should be merged
            into the output group map for that output group name.
        index_import: A `File` for `index-import`.

    Returns:
        A `dict` where the keys are output group names and the values are
        `depset` of `File`s.
    """
    output_groups = {
        name: _process_output_group_files(
            files = files,
            is_indexstores = is_indexstores,
            output_group_name = name,
            additional_bwx_generated = additional_bwx_generated,
            index_import = index_import,
        )
        for name, is_indexstores, files in inputs._output_group_list.to_list()
    }

    output_groups["all_xc"] = memory_efficient_depset(
        transitive = [
            files
            for name, files in output_groups.items()
            if name.startswith("xc ")
        ],
    )
    output_groups["all_xi"] = memory_efficient_depset(
        transitive = [
            files
            for name, files in output_groups.items()
            if name.startswith("xi ")
        ],
    )
    output_groups["all_xl"] = memory_efficient_depset(
        transitive = [
            files
            for name, files in output_groups.items()
            if name.startswith("xl ")
        ],
    )

    return output_groups

input_files = struct(
    collect = _collect_input_files,
    from_resource_bundle = _from_resource_bundle,
    merge = _merge_input_files,
    to_output_groups_fields = _to_output_groups_fields,
)
