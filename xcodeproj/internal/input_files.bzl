"""Module containing functions dealing with target input files."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
    "AppleResourceInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load("@bazel_skylib//lib:sets.bzl", "sets")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":filelists.bzl", "filelists")
load(
    ":files.bzl",
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

def _transitive_extra_files(*, id, files):
    return depset(
        [(
            id,
            tuple([
                normalized_file_path(file)
                for file in files.to_list()
            ]),
        )],
    )

def _collect_transitive_extra_files(id, transitive_info):
    inputs = transitive_info.inputs
    transitive = [inputs.extra_files]
    if not transitive_info.xcode_target:
        transitive.append(
            _transitive_extra_files(id = id, files = inputs.srcs),
        )
        transitive.append(
            _transitive_extra_files(id = id, files = inputs.non_arc_srcs),
        )
        transitive.append(
            _transitive_extra_files(id = id, files = inputs.hdrs),
        )

    return depset(transitive = transitive)

def _collect_transitive_uncategorized(info):
    if info.xcode_target:
        return depset()
    return info.inputs.uncategorized

def _should_ignore_input_attr(attr):
    return (
        # We don't want to include implicit dependencies
        attr.startswith("_") or
        # These are actually Starklark methods, so ignore them
        attr in ("to_json", "to_proto")
    )

def _is_categorized_attr(attr, *, automatic_target_info):
    if attr in automatic_target_info.srcs:
        return True
    elif attr in automatic_target_info.non_arc_srcs:
        return True
    elif attr in automatic_target_info.hdrs:
        return True
    elif attr == automatic_target_info.pch:
        return True
    elif attr in automatic_target_info.infoplists:
        return True
    elif attr == automatic_target_info.entitlements:
        return True
    elif attr in automatic_target_info.exported_symbols_lists:
        return True
    elif attr in automatic_target_info.launchdplists:
        return True
    else:
        return False

def _process_cc_info_headers(headers, *, output_files, pch, generated):
    def _process_header(header):
        if not header.is_source:
            generated.append(header)
        return header

    return [
        _process_header(header)
        for header in headers
        if header not in pch and header not in output_files
    ]

# API

def _collect_input_files(
        *,
        ctx,
        target,
        unfocused = False,
        id,
        platform,
        bundle_resources,
        is_bundle,
        product,
        linker_inputs,
        automatic_target_info,
        additional_files = [],
        transitive_infos,
        avoid_deps = []):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        target: The `Target` to collect inputs from.
        unfocused: Whether the target is unfocused. If `None`, it will be
            determined automatically (this should only be the case for
            `non_xcode_target`s).
        id: A unique identifier for the target.
        platform: A value returned from `platform_info.collect`.
        bundle_resources: Whether resources will be bundled in the generated
            project. If this is `False` then all resources will get added to
            `extra_files` instead of `resources`.
        is_bundle: Whether `target` is a bundle.
        product: A value returned from `process_product`.
        linker_inputs: A value returned from `linker_file_inputs.collect`.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        additional_files: A `list` of `File`s to add to the inputs. This can
            be used to add files to the `generated` and `extra_files` fields
            (e.g. modulemaps or BUILD files).
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
        *   `exported_symbols_lists`: A `depset` of `FilePath`s for
            `exported_symbols_lists`.
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
    exported_symbols_lists = []
    extra_files = []
    generated = []
    hdrs = []
    non_arc_srcs = []
    pch = []
    srcs = []
    uncategorized = []

    # Include BUILD files for the project but not for external repos
    if not target.label.workspace_root:
        extra_files.append(parsed_file_path(ctx.build_file_path))

    # buildifier: disable=uninitialized
    def _handle_file(file, *, attr):
        if file == None:
            return

        categorized = True
        if attr in automatic_target_info.srcs:
            srcs.append(file)
        elif attr in automatic_target_info.non_arc_srcs:
            non_arc_srcs.append(file)
        elif attr in automatic_target_info.hdrs:
            hdrs.append(file)
        elif attr == automatic_target_info.pch:
            # We use `append` instead of setting a single value because
            # assigning to `pch` creates a new local variable instead of
            # assigning to the existing variable
            pch.append(file)
        elif attr in automatic_target_info.infoplists:
            extra_files.append(file_path(file))
        elif attr in automatic_target_info.launchdplists:
            extra_files.append(file_path(file))
        elif attr == automatic_target_info.entitlements:
            # We use `append` instead of setting a single value because
            # assigning to `entitlements` creates a new local variable instead
            # of assigning to the existing variable
            entitlements.append(file)
        elif attr in automatic_target_info.exported_symbols_lists:
            exported_symbols_lists.append(file)
        else:
            categorized = False

        if file.is_source:
            if not categorized and file not in output_files:
                uncategorized.append(normalized_file_path(file))
        elif categorized:
            generated.append(file)

    transitive_extra_files = []

    # buildifier: disable=uninitialized
    def _handle_dep(dep, *, attr):
        # This allows the transitive uncategorized files for target of a
        # categorized attribute to be included in the project
        if (XcodeProjInfo not in dep or
            not _is_categorized_attr(
                attr,
                automatic_target_info = automatic_target_info,
            )):
            return
        transitive_extra_files.append(dep[XcodeProjInfo].inputs.uncategorized)

    for attr in dir(ctx.rule.files):
        if _should_ignore_input_attr(attr):
            continue
        for file in getattr(ctx.rule.files, attr):
            _handle_file(file, attr = attr)

    for attr in dir(ctx.rule.file):
        if _should_ignore_input_attr(attr):
            continue
        _handle_file(getattr(ctx.rule.file, attr), attr = attr)

    for attr in automatic_target_info.all_attrs:
        if _should_ignore_input_attr(attr):
            continue
        dep = getattr(ctx.rule.attr, attr, None)
        if type(dep) == "Target":
            _handle_dep(dep, attr = attr)
        elif type(dep) == "list":
            for dep in dep:
                if type(dep) == "Target":
                    _handle_dep(dep, attr = attr)

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
        framework_files = sets.make(product_framework_files.to_list())
        linker_input_additional_files = [
            file
            for file in linker_input_additional_files
            if not sets.contains(framework_files, file)
        ]
    additional_files = additional_files + linker_input_additional_files

    generated.extend([file for file in additional_files if not file.is_source])
    for file in additional_files:
        extra_files.append(normalized_file_path(file))

    is_resource_bundle_consuming = is_bundle and AppleResourceInfo in target
    label = target.label

    resources = None
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
        bundle_labels = sets.make(resource_bundle_labels.to_list())

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
            if not sets.contains(bundle_labels, label)
        ])

        extra_files.extend(resources_result.extra_files)
        if bundle_resources:
            resource_bundles = resources_result.bundles
            if resources_result.dependencies:
                resource_bundle_dependencies = resources_result.dependencies
            if resources_result.resources:
                resources = depset(resources_result.resources)
        else:
            extra_files.extend(resources_result.resources)
            transitive_extra_files.extend([
                # TODO: Use bundle.label here
                # We need to adjust BwB to show resource bundle targets
                # as unfocused dependency targets.
                depset([(label, bundle.resources)])
                for bundle in resources_result.bundles
            ])
    else:
        resource_bundle_labels = depset(
            transitive = [
                dep[XcodeProjInfo].inputs._resource_bundle_labels
                for dep in avoid_deps
            ],
        )

    # Generically handle CcInfo providing rules. This allows us to pick up
    # headers from `objc_import` and the like.
    if CcInfo in target:
        compilation_context = target[CcInfo].compilation_context
        srcs.extend(_process_cc_info_headers(
            (compilation_context.direct_private_headers +
             compilation_context.direct_public_headers +
             compilation_context.direct_textual_headers),
            output_files = output_files,
            pch = pch,
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

    if id:
        compiling_output_group_name = "xc {}".format(id)
        indexstores_output_group_name = "xi {}".format(id)
        linking_output_group_name = "xl {}".format(id)
        direct_group_list = [
            (compiling_output_group_name, False, generated_depset),
            (indexstores_output_group_name, True, indexstores_depset),
            (linking_output_group_name, False, depset()),
        ]
    else:
        compiling_output_group_name = None
        indexstores_output_group_name = None
        linking_output_group_name = None
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
        resources = resources,
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
        exported_symbols_lists = depset(exported_symbols_lists),
        xccurrentversions = depset(
            xccurrentversions,
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
        indexstores = indexstores_depset,
        extra_files = depset(
            [(label, tuple(extra_files))] if extra_files else None,
            transitive = [
                _collect_transitive_extra_files(label, info)
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
        _non_target_swift_info_modules = depset(),
        _output_group_list = depset(),
        _product_framework_files = depset(),
        _resource_bundle_labels = depset(),
        _resource_bundle_uncategorized = depset(),
        srcs = depset(),
        non_arc_srcs = depset(),
        hdrs = depset(),
        pch = None,
        resources = depset(bundle.resources),
        resource_bundles = depset(),
        resource_bundle_dependencies = bundle.dependencies,
        entitlements = None,
        exported_symbols_lists = depset(),
        xccurrentversions = depset(),
        generated = depset(),
        important_generated = depset(),
        unfocused_generated_compiling = None,
        unfocused_generated_indexstores = None,
        unfocused_generated_linking = None,
        indexstores = depset(),
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
        resources = None,
        resource_bundles = depset(
            transitive = [
                info.inputs.resource_bundles
                for _, info in transitive_infos
            ],
        ),
        entitlements = None,
        exported_symbols_lists = depset(),
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
        ctx,
        files,
        is_indexstores,
        output_group_name,
        additional_generated,
        index_import):
    # `list` copy is needed for some reason to prevent depset from changing
    # underneath us. Without this it's nondeterministic which files are in it.
    generated_depsets = list(additional_generated.get(output_group_name, []))

    if is_indexstores:
        filelist = filelists.write(
            ctx = ctx,
            rule_name = ctx.attr.name,
            name = output_group_name.replace("/", "_"),
            files = files,
        )
        direct = [filelist, index_import]

        # We don't want to declare indexstore files as outputs, because they
        # expand to individual files and blow up the BEP
        transitive = generated_depsets
    else:
        direct = None
        transitive = generated_depsets + [files]

    return depset(direct, transitive = transitive)

def _to_output_groups_fields(
        *,
        ctx,
        inputs,
        additional_generated = {},
        index_import):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        ctx: The rule context.
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
            ctx = ctx,
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
