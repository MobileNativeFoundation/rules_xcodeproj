"""Module containing functions dealing with target input files."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
    "AppleResourceInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":filelists.bzl", "filelists")
load(
    ":files.bzl",
    "FRAMEWORK_EXTENSIONS",
    "RESOURCES_FOLDER_TYPE_EXTENSIONS",
    "file_path",
    "normalized_file_path",
    "parsed_file_path",
)
load(":linker_input_files.bzl", "linker_input_files")
load(":output_files.bzl", "parse_swift_info_module", "swift_to_outputs")
load(":providers.bzl", "XcodeProjInfo")
load(":resources.bzl", "collect_resources")
load(":target_properties.bzl", "should_include_non_xcode_outputs")

# Utility

def _collect_transitive_uncategorized(info):
    if info.xcode_target:
        return depset()
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

# API

_C_EXTENSIONS = {
    "c": None,
    "m": None,
}

_CXX_EXTENSIONS = {
    "cc": None,
    "cpp": None,
    "cxx": None,
    "c++": None,
    "C": None,
    "cu": None,
    "cl": None,
    "mm": None,
}

def _collect_input_files(
        *,
        ctx,
        target,
        unfocused = False,
        id,
        platform,
        is_bundle,
        product,
        linker_inputs,
        automatic_target_info,
        additional_files = [],
        modulemaps = None,
        transitive_infos,
        avoid_deps = []):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        target: The `Target` to collect inputs from.
        unfocused: Whether the target is unfocused. If `None`, it will be
            determined automatically (this should only be the case for
            `non_xcode_target`s).
        id: A unique identifier for the target. Will be `None` for non-Xcode
            targets.
        platform: A value returned from `platform_info.collect`.
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
        A `struct` with the following fields:

        *   `srcs`: A `depset` of `File`s that are inputs to `target`'s
            `srcs`-like attributes.
        *   `non_arc_srcs`: A `depset` of `File`s that are inputs to
            `target`'s `non_arc_srcs`-like attributes.
        *   `hdrs`: A `depset` of `File`s that are inputs to `target`'s
            `hdrs`-like attributes.
        *   `resources`: A `depset` of `FilePath`s that are inputs to `target`'s
            `resources`-like and `structured_resources`-like attributes.
        *   `xccurrentversions`: A `depset` of `.xccurrentversion` `File`s that
            are in `resources`.
        *   `generated`: A `depset` of generated `File`s that are inputs to
            `target` or its transitive dependencies.
        *   `important_generated`: A `depset` of important generated `File`s
            that are inputs to `target` or its transitive dependencies. These
            differ from `generated` in that they will be generated as part of
            project generation, to ensure they are created before Xcode is
            opened. Entitlements are an example of this, as Xcode won't even
            start a build if they are missing.
        *   `extra_files`: A `depset` of `FilePath`s that should be included in
            the project, but aren't necessarily inputs to the target. This also
            includes some categorized files of transitive dependencies
            that didn't create an Xcode target.
        *   `uncategorized`: A `depset` of `FilePath`s that are inputs to
            `target` didn't fall into one of the more specific (e.g. `srcs`)
            categories. These will only be included in the Xcode project if this
            target becomes an input to another target's categorized attribute.
    """
    output_files = target.files.to_list()

    entitlements = []
    c_srcs = []
    cxx_srcs = []
    hdrs = []
    non_arc_srcs = []
    pch = []
    srcs = []
    uncategorized = []

    generated = [file for file in additional_files if not file.is_source]
    extra_files = [file_path(file) for file in additional_files]

    # Include BUILD files for the project but not for external repos
    if not target.label.workspace_root:
        extra_files.append(parsed_file_path(ctx.build_file_path))

    # buildifier: disable=uninitialized
    def _handle_srcs_file(file):
        srcs.append(file)
        extension = file.extension
        if extension in _C_EXTENSIONS:
            c_srcs.append(file)
        elif extension in _CXX_EXTENSIONS:
            cxx_srcs.append(file)

    # buildifier: disable=uninitialized
    def _handle_non_arc_srcs_file(file):
        non_arc_srcs.append(file)
        extension = file.extension
        if extension in _C_EXTENSIONS:
            c_srcs.append(file)
        elif extension in _CXX_EXTENSIONS:
            cxx_srcs.append(file)

    # buildifier: disable=uninitialized
    def _handle_hdrs_file(file):
        hdrs.append(file)

    # buildifier: disable=uninitialized
    def _handle_pch_file(file):
        # We use `append` instead of setting a single value because
        # assigning to `pch` creates a new local variable instead of
        # assigning to the existing variable
        pch.append(file)

    # buildifier: disable=uninitialized
    def _handle_entitlements_file(file):
        # We use `append` instead of setting a single value because
        # assigning to `entitlements` creates a new local variable instead
        # of assigning to the existing variable
        entitlements.append(file)

    # buildifier: disable=uninitialized
    def _handle_extrafiles_file(file):
        extra_files.append(file_path(file))

    file_handlers = {}

    if id:
        for attr in automatic_target_info.srcs:
            file_handlers[attr] = _handle_srcs_file
        for attr in automatic_target_info.non_arc_srcs:
            file_handlers[attr] = _handle_non_arc_srcs_file
        for attr in automatic_target_info.hdrs:
            file_handlers[attr] = _handle_hdrs_file
    else:
        # Turn source files into extra files for non-Xcode targets
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
    if automatic_target_info.entitlements:
        file_handlers[automatic_target_info.entitlements] = (
            _handle_entitlements_file
        )
    for attr in automatic_target_info.exported_symbols_lists:
        file_handlers[attr] = _handle_extrafiles_file

    categorized_files = {}

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
            if not categorized and file not in output_files:
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

    for attr in automatic_target_info.all_attrs:
        if _should_ignore_input_attr(attr):
            continue

        if attr not in file_handlers:
            # Only attributes in `file_handlers` are categorized
            continue

        dep = getattr(ctx.rule.attr, attr, None)

        dep_type = type(dep)
        if dep_type == "Target":
            _handle_dep(dep)
        elif dep_type == "list":
            if not dep or type(dep[0]) != "Target":
                continue
            for list_dep in dep:
                _handle_dep(list_dep)

    product_framework_files = depset(
        transitive = [
            info.inputs._product_framework_files
            for attr, info in transitive_infos
            if (info.target_type in
                automatic_target_info.xcode_targets.get(attr, [None]))
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
    label = target.label

    resources = None
    folder_resources = None
    resource_bundles = None
    resource_bundle_dependencies = None
    xccurrentversions = None
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
        xccurrentversions = resources_result.xccurrentversions

        bundle_labels_list = [
            bundle.label
            for bundle in resources_result.bundles
        ]
        resource_bundle_labels = depset(
            bundle_labels_list if bundle_labels_list else None,
            transitive = [
                dep[XcodeProjInfo].inputs._resource_bundle_labels
                for dep in avoid_deps
            ],
        )
        bundle_labels = {
            label: None
            for label in resource_bundle_labels.to_list()
        }

        extra_files.extend([
            file
            for label, files in depset(
                transitive = [
                    info.inputs._resource_bundle_uncategorized
                    for attr, info in transitive_infos
                    if (info.target_type in
                        automatic_target_info.xcode_targets.get(attr, [None]))
                ],
            ).to_list()
            for file in files
            if label not in bundle_labels
        ])

        extra_files.extend(resources_result.extra_files)
        resource_bundles = resources_result.bundles
        if resources_result.dependencies:
            resource_bundle_dependencies = resources_result.dependencies
        if resources_result.resources:
            resources = depset(resources_result.resources)
        if resources_result.folder_resources:
            folder_resources = depset(resources_result.folder_resources)
    else:
        resource_bundle_labels = depset(
            transitive = [
                dep[XcodeProjInfo].inputs._resource_bundle_labels
                for dep in avoid_deps
            ],
        )

    # Generically handle CcInfo providing rules. This allows us to pick up
    # headers from `objc_import` and the like.
    if SwiftInfo in target:
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

    # Collect unfocused target info
    indexstores = []
    unfocused_libraries = None
    if should_include_non_xcode_outputs(ctx = ctx):
        if unfocused == None:
            dep_compilation_providers = comp_providers.merge(
                transitive_compilation_providers = [
                    (info.xcode_target, info.compilation_providers)
                    for attr, info in transitive_infos
                    if (info.target_type in
                        automatic_target_info.xcode_targets.get(attr, [None]))
                ],
            )
            (
                direct_libraries,
                transitive_libraries,
            ) = linker_input_files.get_library_static_libraries(
                linker_inputs = linker_inputs,
                dep_compilation_providers = dep_compilation_providers,
            )

            unfocused_generated_linking = transitive_libraries

            unfocused = bool(direct_libraries)
            if unfocused:
                generated.extend(transitive_libraries)
                unfocused_libraries = depset(
                    [
                        file_path(file)
                        for file in transitive_libraries
                    ],
                )
        else:
            unfocused_generated_linking = (
                linker_input_files.get_transitive_static_libraries(
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
            non_target_swift_info_modules = depset(
                transitive = [
                    info.inputs._non_target_swift_info_modules
                    for attr, info in transitive_infos
                    if (info.target_type in
                        automatic_target_info.xcode_targets.get(attr, [None]))
                ],
            )
        for module in non_target_swift_info_modules.to_list():
            compiled, indexstore = swift_to_outputs(
                parse_swift_info_module(module),
            )
            generated.extend(compiled)
            if indexstore:
                indexstores.append(indexstore)

        if is_swift:
            unfocused_swift_info_modules = target[SwiftInfo].transitive_modules
        else:
            unfocused_swift_info_modules = non_target_swift_info_modules

        unfocused_generated_compiling = []
        unfocused_generated_indexstores = []
        for module in unfocused_swift_info_modules.to_list():
            compiled, indexstore = swift_to_outputs(
                parse_swift_info_module(module),
            )

            if compiled:
                # We only need the single swiftmodule in order to download
                # everything from the remote cache (because of
                # `--experimental_remote_download_regex`). Reducing the number
                # of items in an output group keeps the BEP small.
                unfocused_generated_compiling.append(compiled[0])
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
        non_target_swift_info_modules = depset()
        unfocused_generated_compiling = None
        unfocused_generated_indexstores = None
        unfocused_generated_linking = None

    important_generated = [
        file
        for file in entitlements
        if not file.is_source
    ]

    generated_depset = depset(
        generated if generated else None,
        transitive = [
            info.inputs.generated
            for attr, info in transitive_infos
            if (info.target_type in
                automatic_target_info.xcode_targets.get(attr, [None]))
        ],
    )
    indexstores_depset = depset(
        indexstores if indexstores else None,
        transitive = [
            info.inputs.indexstores
            for attr, info in transitive_infos
            if (info.target_type in
                automatic_target_info.xcode_targets.get(attr, [None]))
        ],
    )

    if modulemaps:
        modulemaps = [f for f in modulemaps if not f.is_source]
        modulemaps_depset = depset(modulemaps)
    else:
        modulemaps_depset = depset(
            transitive = [
                info.inputs._modulemaps
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        )

        # Purposeful flattening to work around large BEP issue.
        # This is because we only get modulemaps already flattened. Ideally we
        # would get a `depset` for the modulemaps, so they would be properly
        # represented in the BEP.
        modulemaps = modulemaps_depset.to_list()

    if id:
        compiling_output_group_name = "xc {}".format(id)
        indexstores_output_group_name = "xi {}".format(id)
        linking_output_group_name = "xl {}".format(id)

        compiling_files = depset(
            modulemaps,
            transitive = [generated_depset],
        )

        indexstores_filelist = filelists.write(
            ctx = ctx,
            rule_name = ctx.rule.attr.name,
            name = "xi",
            files = indexstores_depset,
        )

        # We don't want to declare indexstore files as outputs, because they
        # expand to individual files and blow up the BEP
        indexstores_files = depset([indexstores_filelist])

        direct_group_list = [
            (compiling_output_group_name, False, compiling_files),
            (indexstores_output_group_name, True, indexstores_files),
            (linking_output_group_name, False, depset()),
        ]
    else:
        compiling_output_group_name = None
        indexstores_output_group_name = None
        linking_output_group_name = None
        compiling_files = generated_depset
        direct_group_list = None

    if not unfocused_libraries:
        unfocused_libraries = depset(
            transitive = [
                info.inputs.unfocused_libraries
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        )

    if is_resource_bundle_consuming:
        # We've consumed them above
        resource_bundle_uncategorized = depset()
    else:
        # TODO: Remove hard-coded "apple_bundle_import" check
        if (AppleResourceBundleInfo in target and
            ctx.rule.kind != "apple_bundle_import"):
            resource_bundle_uncategorized = uncategorized
            uncategorized = []
        else:
            resource_bundle_uncategorized = None

        if resource_bundle_uncategorized:
            resource_bundle_uncategorized_direct = [
                (target.label, tuple(resource_bundle_uncategorized)),
            ]
        else:
            resource_bundle_uncategorized_direct = None

        resource_bundle_uncategorized = depset(
            resource_bundle_uncategorized_direct,
            transitive = [
                info.inputs._resource_bundle_uncategorized
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        )

    return struct(
        _modulemaps = modulemaps_depset,
        _non_target_swift_info_modules = non_target_swift_info_modules,
        _output_group_list = depset(
            direct_group_list,
            transitive = [
                info.inputs._output_group_list
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        ),
        _product_framework_files = product_framework_files,
        _resource_bundle_labels = resource_bundle_labels,
        _resource_bundle_uncategorized = resource_bundle_uncategorized,
        srcs = depset(srcs),
        non_arc_srcs = depset(non_arc_srcs),
        hdrs = depset(hdrs),
        pch = pch[0] if pch else None,
        has_c_sources = bool(c_srcs),
        has_cxx_sources = bool(cxx_srcs),
        resources = resources,
        folder_resources = folder_resources,
        resource_bundles = depset(
            resource_bundles,
            transitive = [
                info.inputs.resource_bundles
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        ),
        resource_bundle_dependencies = depset(
            resource_bundle_dependencies,
        ),
        entitlements = entitlements[0] if entitlements else None,
        xccurrentversions = depset(
            [(label, tuple(xccurrentversions))] if xccurrentversions else None,
            transitive = [
                info.inputs.xccurrentversions
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        ),
        generated = generated_depset,
        important_generated = depset(
            important_generated if important_generated else None,
            transitive = [
                info.inputs.important_generated
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        ),
        unfocused_generated_compiling = unfocused_generated_compiling,
        unfocused_generated_indexstores = unfocused_generated_indexstores,
        unfocused_generated_linking = unfocused_generated_linking,
        has_generated_files = bool(generated) or bool([
            True
            for attr, info in transitive_infos
            if (info.inputs.has_generated_files and
                (info.target_type in
                 automatic_target_info.xcode_targets.get(attr, [None])))
        ]),
        compiling_files = compiling_files,
        indexstores = indexstores_depset,
        extra_files = depset(
            [(label, tuple(extra_files))] if extra_files else None,
            transitive = [
                depset(transitive = [info.inputs.extra_files])
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ] + transitive_extra_files,
        ),
        uncategorized = depset(
            [(label, tuple(uncategorized))] if uncategorized else None,
            transitive = [
                _collect_transitive_uncategorized(info)
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        ),
        unfocused_libraries = unfocused_libraries,
        compiling_output_group_name = compiling_output_group_name,
        indexstores_output_group_name = indexstores_output_group_name,
        linking_output_group_name = linking_output_group_name,
    )

def _from_resource_bundle(bundle):
    return struct(
        _modulemaps = depset(),
        _non_target_swift_info_modules = depset(),
        _output_group_list = depset(),
        _product_framework_files = depset(),
        _resource_bundle_labels = depset(),
        _resource_bundle_uncategorized = depset(),
        srcs = depset(),
        non_arc_srcs = depset(),
        hdrs = depset(),
        pch = None,
        has_c_sources = False,
        has_cxx_sources = False,
        resources = depset(bundle.resources),
        folder_resources = depset(bundle.folder_resources),
        resource_bundles = depset(),
        resource_bundle_dependencies = bundle.dependencies,
        entitlements = None,
        xccurrentversions = depset(),
        generated = depset(),
        important_generated = depset(),
        unfocused_generated_compiling = None,
        unfocused_generated_indexstores = None,
        unfocused_generated_linking = None,
        indexstores = depset(),
        compiling_files = depset(),
        extra_files = depset(),
        uncategorized = depset(),
        unfocused_libraries = depset(),
        compiling_output_group_name = None,
        indexstores_output_group_name = None,
        linking_output_group_name = None,
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
    return struct(
        _modulemaps = depset(
            transitive = [
                info.inputs._modulemaps
                for _, info in transitive_infos
            ],
        ),
        _non_target_swift_info_modules = depset(
            transitive = [
                info.inputs._non_target_swift_info_modules
                for _, info in transitive_infos
            ],
        ),
        _output_group_list = depset(
            transitive = [
                info.inputs._output_group_list
                for _, info in transitive_infos
            ],
        ),
        _product_framework_files = depset(
            transitive = [
                info.inputs._product_framework_files
                for _, info in transitive_infos
            ],
        ),
        _resource_bundle_labels = depset(
            transitive = [
                info.inputs._resource_bundle_labels
                for _, info in transitive_infos
            ],
        ),
        _resource_bundle_uncategorized = depset(
            transitive = [
                info.inputs._resource_bundle_uncategorized
                for _, info in transitive_infos
            ],
        ),
        srcs = depset(),
        non_arc_srcs = depset(),
        hdrs = depset(),
        pch = None,
        has_c_sources = False,
        has_cxx_sources = False,
        resources = None,
        folder_resources = None,
        resource_bundles = depset(
            transitive = [
                info.inputs.resource_bundles
                for _, info in transitive_infos
            ],
        ),
        entitlements = None,
        xccurrentversions = depset(
            transitive = [
                info.inputs.xccurrentversions
                for _, info in transitive_infos
            ],
        ),
        generated = depset(
            extra_generated if extra_generated else None,
            transitive = [
                info.inputs.generated
                for _, info in transitive_infos
            ],
        ),
        important_generated = depset(
            transitive = [
                info.inputs.important_generated
                for _, info in transitive_infos
            ],
        ),
        unfocused_generated_compiling = None,
        unfocused_generated_indexstores = None,
        unfocused_generated_linking = None,
        has_generated_files = bool([
            True
            for _, info in transitive_infos
            if info.inputs.has_generated_files
        ]),
        indexstores = depset(
            transitive = [
                info.inputs.indexstores
                for _, info in transitive_infos
            ],
        ),
        compiling_files = depset(),
        extra_files = depset(
            transitive = [
                info.inputs.extra_files
                for _, info in transitive_infos
            ],
        ),
        uncategorized = depset(
            transitive = [
                info.inputs.uncategorized
                for _, info in transitive_infos
            ],
        ),
        unfocused_libraries = depset(
            transitive = [
                info.inputs.unfocused_libraries
                for _, info in transitive_infos
            ],
        ),
        compiling_output_group_name = None,
        indexstores_output_group_name = None,
        linking_output_group_name = None,
    )

def _process_output_group_files(
        *,
        files,
        is_indexstores,
        output_group_name,
        additional_generated,
        index_import):
    # `list` copy is needed for some reason to prevent depset from changing
    # underneath us. Without this it's nondeterministic which files are in it.
    generated_depsets = list(additional_generated.get(output_group_name, []))

    if is_indexstores:
        direct = [index_import]
    else:
        direct = None

    return depset(direct, transitive = generated_depsets + [files])

def _to_output_groups_fields(
        *,
        inputs,
        additional_generated = {},
        index_import):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        inputs: A value returned from `input_files.collect`.
        additional_generated: A `dict` that maps the output group name of
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
            additional_generated = additional_generated,
            index_import = index_import,
        )
        for name, is_indexstores, files in inputs._output_group_list.to_list()
    }

    output_groups["all_xc"] = depset(
        transitive = [
            files
            for name, files in output_groups.items()
            if name.startswith("xc ")
        ],
    )
    output_groups["all_xi"] = depset(
        transitive = [
            files
            for name, files in output_groups.items()
            if name.startswith("xi ")
        ],
    )
    output_groups["all_xl"] = depset(
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
