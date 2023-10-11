"""Module containing functions dealing with target input files."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo", "SwiftProtoInfo")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_LIST",
    "memory_efficient_depset",
)
load(":linker_input_files.bzl", "linker_input_files")
load(":providers.bzl", "XcodeProjInfo")
load(":resources.bzl", "collect_resources")

# Utility

_HEADER_EXTENSIONS = {
    "def": None,
    "h": None,
    "hh": None,
    "hpp": None,
    "hxx": None,
    "ilc": None,
    "inc": None,
    "ipp": None,
    "tpp": None,
}

_IGNORE_ATTR = {
    "to_json": None,
    "to_proto": None,
}

def _collect_transitive_uncategorized_files(info):
    if info.xcode_target:
        return EMPTY_DEPSET
    return info.inputs.uncategorized_files

def _inner_merge_input_files(
        *,
        generated,
        resource_bundles,
        transitive_infos,
        xccurrentversions):
    return struct(
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
        generated = memory_efficient_depset(
            generated,
            transitive = [
                info.inputs.generated
                for info in transitive_infos
            ],
        ),
        resource_bundles = memory_efficient_depset(
            resource_bundles,
            transitive = [
                info.inputs.resource_bundles
                for info in transitive_infos
            ],
        ),
        important_generated = memory_efficient_depset(
            transitive = [
                info.inputs.important_generated
                for info in transitive_infos
            ],
        ),
        uncategorized_files = memory_efficient_depset(
            transitive = [
                info.inputs.uncategorized_files
                for info in transitive_infos
            ],
        ),
        unsupported_extra_files = memory_efficient_depset(
            transitive = [
                info.inputs.unsupported_extra_files
                for info in transitive_infos
            ],
        ),
        xccurrentversions = memory_efficient_depset(
            xccurrentversions,
            transitive = [
                info.inputs.xccurrentversions
                for info in transitive_infos
            ],
        ),
    )

def _should_ignore_input_attr(attr):
    return (
        # We don't want to include implicit dependencies
        attr[0] == "_" or
        # These are actually Starklark methods, so ignore them
        attr in _IGNORE_ATTR
    )

def _process_cc_info_headers(headers, *, exclude_headers, generated):
    def _process_header(header_file):
        exclude_headers[header_file] = None
        if not header_file.is_source:
            generated.append(header_file)
        return header_file

    files = []
    for header in headers:
        if header in exclude_headers:
            continue
        files.append(_process_header(header))

    return files

def _process_files_and_deps(
        *,
        additional_src_files,
        additional_src_file_handler,
        attrs,
        collect_uncategorized_files,
        extra_files,
        file_handlers,
        generated,
        rule_attr,
        rule_file,
        rule_files,
        target):
    categorized_files = {}
    uncategorized_files = []
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
                    uncategorized_files.append(file)
        elif categorized:
            generated.append(file)

    transitive_extra_files = []

    # buildifier: disable=uninitialized
    def _handle_dep(dep):
        # This allows the transitive uncategorized files for target of a
        # categorized attribute to be included in the project
        if XcodeProjInfo not in dep:
            return
        transitive_extra_files.append(
            dep[XcodeProjInfo].inputs.uncategorized_files,
        )

    for attr in dir(rule_files):
        if _should_ignore_input_attr(attr):
            continue

        handler = file_handlers.get(attr, None)

        if not collect_uncategorized_files and not handler:
            continue

        for file in getattr(rule_files, attr):
            _handle_file(file, handler = handler)

    for attr in dir(rule_file):
        if _should_ignore_input_attr(attr):
            continue

        handler = file_handlers.get(attr, None)

        if not collect_uncategorized_files and not handler:
            continue

        _handle_file(getattr(rule_file, attr), handler = handler)

    for file in additional_src_files:
        _handle_file(file, handler = additional_src_file_handler)

    for attr in attrs:
        if _should_ignore_input_attr(attr):
            continue

        if attr not in file_handlers:
            # Only attributes in `file_handlers` are categorized
            continue

        dep = getattr(rule_attr, attr)

        dep_type = type(dep)
        if dep_type == "Target":
            _handle_dep(dep)
        elif dep_type == "list":
            if not dep or type(dep[0]) != "Target":
                continue
            for list_dep in dep:
                _handle_dep(list_dep)

    if CcInfo in target:
        compilation_context = target[CcInfo].compilation_context
        extra_files.extend(
            _process_cc_info_headers(
                compilation_context.direct_private_headers,
                exclude_headers = categorized_files,
                generated = generated,
            ),
        )
        extra_files.extend(
            _process_cc_info_headers(
                compilation_context.direct_public_headers,
                exclude_headers = categorized_files,
                generated = generated,
            ),
        )
        extra_files.extend(
            _process_cc_info_headers(
                compilation_context.direct_textual_headers,
                exclude_headers = categorized_files,
                generated = generated,
            ),
        )

    return (
        transitive_extra_files,
        uncategorized_files,
        xccurrentversions,
    )

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
        build_mode,
        target,
        attrs,
        id,
        platform,
        is_resource_bundle_consuming = False,
        product,
        linker_inputs,
        automatic_target_info,
        additional_files = EMPTY_LIST,
        transitive_infos,
        avoid_deps = EMPTY_LIST):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to collect inputs from.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        id: A unique identifier for the target. Will be `None` for non-Xcode
            targets.
        platform: A value returned from `platforms.collect`.
        is_resource_bundle_consuming: Whether `target` is a resource bundle
            consuming target (i.e. a bundle with a `AppleResourceInfo`
            provider).
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
        A `tuple` with two elements:

        *   A `struct`, which will only be used within the aspect, with the
            following fields:

            *   `generated`: A `depset` of generated `File`s that are inputs to
                `target` or its transitive dependencies.
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
                `target` and didn't fall into one of the more specific (e.g.
                `srcs`) categories. These will only be included in the Xcode
                project if this target becomes an input to another target's
                categorized attribute.
    """
    entitlements = []
    c_sources = {}
    cxx_sources = {}
    non_arc_srcs = []
    pch = []
    srcs = []

    generated = [file for file in additional_files if not file.is_source]
    extra_files = list(additional_files)

    label = automatic_target_info.label

    # Include BUILD files for the project but not for external repos
    extra_file_paths = []
    if not label.workspace_root:
        extra_file_paths.append(ctx.build_file_path)

    # buildifier: disable=uninitialized
    def _handle_srcs_file(file):
        extension = file.extension
        if extension in C_EXTENSIONS:
            c_sources[file.path] = None
        elif extension in CXX_EXTENSIONS:
            cxx_sources[file.path] = None
        if extension in _HEADER_EXTENSIONS:
            extra_files.append(file)
        else:
            srcs.append(file)

    # buildifier: disable=uninitialized
    def _handle_non_arc_srcs_file(file):
        extension = file.extension
        if extension in C_EXTENSIONS:
            c_sources[file.path] = None
        elif extension in CXX_EXTENSIONS:
            cxx_sources[file.path] = None
        if extension in _HEADER_EXTENSIONS:
            extra_files.append(file)
        else:
            non_arc_srcs.append(file)

    # buildifier: disable=uninitialized
    def _handle_pch_file(file):
        # We use `append` instead of setting a single value because
        # assigning to `pch` creates a new local variable instead of
        # assigning to the existing variable
        pch.append(file)
        extra_files.append(file)

    # buildifier: disable=uninitialized
    def _handle_entitlements_file(file):
        # We use `append` instead of setting a single value because
        # assigning to `entitlements` creates a new local variable instead
        # of assigning to the existing variable
        entitlements.append(file)
        extra_files.append(file)

    # buildifier: disable=uninitialized
    def _handle_extrafiles_file(file):
        extra_files.append(file)

    file_handlers = {}

    if id:
        for attr in automatic_target_info.srcs:
            file_handlers[attr] = _handle_srcs_file
        for attr in automatic_target_info.non_arc_srcs:
            file_handlers[attr] = _handle_non_arc_srcs_file
    else:
        # Turn source files into extra files for non-Xcode targets
        for attr in automatic_target_info.srcs:
            file_handlers[attr] = _handle_extrafiles_file
        for attr in automatic_target_info.non_arc_srcs:
            file_handlers[attr] = _handle_extrafiles_file

    if automatic_target_info.pch:
        file_handlers[automatic_target_info.pch] = _handle_pch_file
    for attr in automatic_target_info.hdrs:
        file_handlers[attr] = _handle_extrafiles_file
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

    if SwiftProtoInfo in target:
        additional_src_files = target[SwiftProtoInfo].pbswift_files.to_list()
    else:
        additional_src_files = EMPTY_LIST

    (
        transitive_extra_files,
        uncategorized_files,
        xccurrentversions,
    ) = _process_files_and_deps(
        additional_src_files = additional_src_files,
        additional_src_file_handler = _handle_srcs_file,
        attrs = attrs,
        collect_uncategorized_files = (
            automatic_target_info.collect_uncategorized_files
        ),
        extra_files = extra_files,
        file_handlers = file_handlers,
        generated = generated,
        rule_attr = ctx.rule.attr,
        rule_file = ctx.rule.file,
        rule_files = ctx.rule.files,
        target = target,
    )

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
        extra_files.extend(linker_input_additional_files)

    if is_resource_bundle_consuming:
        resources_result = collect_resources(
            build_mode = build_mode,
            platform = platform,
            resource_info = target[AppleResourceInfo],
            avoid_resource_infos = [
                dep[AppleResourceInfo]
                for dep in avoid_deps
                if AppleResourceInfo in dep
            ],
        )

        folder_resources = memory_efficient_depset(
            resources_result.folder_resources,
        )
        resources = memory_efficient_depset(resources_result.resources)
        resource_bundle_dependencies = memory_efficient_depset(
            resources_result.dependencies,
        )
        resource_bundles = resources_result.bundles

        generated.extend(resources_result.generated)
        xccurrentversions.extend(resources_result.xccurrentversions)

        resource_bundle_labels = memory_efficient_depset(
            [
                bundle.label
                for bundle in resources_result.bundles
            ],
            transitive = [
                dep[XcodeProjInfo].inputs._resource_bundle_labels
                for dep in avoid_deps
            ],
        )
        resource_bundle_uncategorized = EMPTY_DEPSET
        transitive_extra_files.append(
            memory_efficient_depset(
                transitive = [
                    info.inputs._resource_bundle_uncategorized
                    for info in transitive_infos
                ],
            ),
        )
    else:
        folder_resources = EMPTY_DEPSET
        resources = EMPTY_DEPSET
        resource_bundle_dependencies = EMPTY_DEPSET
        resource_bundle_labels = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_labels
                for info in transitive_infos
            ],
        )
        resource_bundle_uncategorized = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_uncategorized
                for info in transitive_infos
            ],
        )
        resource_bundles = None

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

    label_str = str(label)

    return (
        struct(
            entitlements = entitlements[0] if entitlements else None,
            extra_file_paths = memory_efficient_depset(extra_file_paths),
            extra_files = memory_efficient_depset(
                extra_files,
                transitive = [
                    t.files
                    for t, file_label_str in ctx.attr._owned_extra_files.items()
                    if file_label_str == label_str
                ] + transitive_extra_files,
            ),
            folder_resources = folder_resources,
            generated = generated_depset,
            c_sources = c_sources,
            cxx_sources = cxx_sources,
            non_arc_srcs = non_arc_srcs,
            pch = pch[0] if pch else None,
            resource_bundle_dependencies = resource_bundle_dependencies,
            resources = resources,
            srcs = srcs,
        ),
        struct(
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
            generated = generated_depset,
            important_generated = memory_efficient_depset(
                important_generated,
                transitive = [
                    info.inputs.important_generated
                    for info in transitive_infos
                ],
            ),
            uncategorized_files = memory_efficient_depset(
                uncategorized_files,
                transitive = [
                    _collect_transitive_uncategorized_files(info)
                    for info in transitive_infos
                ],
            ),
            unsupported_extra_files = memory_efficient_depset(
                transitive = [
                    info.inputs.unsupported_extra_files
                    for info in transitive_infos
                ],
            ),
            xccurrentversions = memory_efficient_depset(
                [
                    (label, tuple(xccurrentversions)),
                ] if xccurrentversions else None,
                transitive = [
                    info.inputs.xccurrentversions
                    for info in transitive_infos
                ],
            ),
        ),
    )

def _collect_unsupported_input_files(
        *,
        ctx,
        build_mode,
        target,
        attrs,
        automatic_target_info,
        include_extra_files,
        is_resource_bundle,
        transitive_infos):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to collect inputs from.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        include_extra_files: Whether to include extra files in the inputs.
        is_resource_bundle: Whether `target` is a resource bundle.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of `target`.

    Returns:
        A `tuple` with two elements:

        *   A `struct`, which will only be used within the aspect, with the
            following fields:

            *   `generated`: A `depset` of generated `File`s that are inputs to
                `target` or its transitive dependencies.
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
                `target` and didn't fall into one of the more specific (e.g.
                `srcs`) categories. These will only be included in the Xcode
                project if this target becomes an input to another target's
                categorized attribute.
    """
    generated = []
    extra_file_paths = []
    extra_files = []

    label = automatic_target_info.label

    # Include BUILD files for the project but not for external repos
    if include_extra_files and not label.workspace_root:
        extra_file_paths.append(ctx.build_file_path)

    if include_extra_files:
        # buildifier: disable=uninitialized
        def _handle_extrafiles_file(file):
            extra_files.append(file)
    else:
        # buildifier: disable=uninitialized
        def _handle_extrafiles_file(_file):
            pass

    # Turn source files into extra files for non-Xcode targets
    file_handlers = {}
    for attr in automatic_target_info.srcs:
        file_handlers[attr] = _handle_extrafiles_file
    for attr in automatic_target_info.non_arc_srcs:
        file_handlers[attr] = _handle_extrafiles_file
    for attr in automatic_target_info.hdrs:
        file_handlers[attr] = _handle_extrafiles_file

    (
        transitive_extra_files,
        uncategorized_files,
        xccurrentversions,
    ) = _process_files_and_deps(
        additional_src_files = EMPTY_LIST,
        additional_src_file_handler = None,
        attrs = attrs,
        collect_uncategorized_files = (
            automatic_target_info.collect_uncategorized_files
        ),
        extra_files = extra_files,
        file_handlers = file_handlers,
        generated = generated,
        rule_attr = ctx.rule.attr,
        rule_file = ctx.rule.file,
        rule_files = ctx.rule.files,
        target = target,
    )

    if is_resource_bundle:
        resource_bundle_uncategorized = uncategorized_files
    else:
        resource_bundle_uncategorized = None

    return struct(
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
            resource_bundle_uncategorized,
            transitive = [
                info.inputs._resource_bundle_uncategorized
                for info in transitive_infos
            ],
        ),
        generated = memory_efficient_depset(
            generated,
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
        resource_bundles = memory_efficient_depset(
            transitive = [
                info.inputs.resource_bundles
                for info in transitive_infos
            ],
        ),
        uncategorized_files = memory_efficient_depset(
            uncategorized_files,
            transitive = [
                _collect_transitive_uncategorized_files(info)
                for info in transitive_infos
            ],
        ),
        unsupported_extra_files = memory_efficient_depset(
            extra_files,
            transitive = [
                info.inputs.unsupported_extra_files
                for info in transitive_infos
            ] + (transitive_extra_files if include_extra_files else []),
        ),
        xccurrentversions = memory_efficient_depset(
            [
                (label, tuple(xccurrentversions)),
            ] if xccurrentversions else None,
            transitive = [
                info.inputs.xccurrentversions
                for info in transitive_infos
            ],
        ),
    )

def _merge_input_files(*, extra_generated = None, transitive_infos):
    """Creates merged inputs.

    Args:
        extra_generated: An optional `list` of `File`s to added to `generated`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to the one returned from `input_files.collect`. The
        values potentially include the inputs of the transitive dependencies,
        via `transitive_infos` (e.g. `generated` and `extra_files`).
    """
    return _inner_merge_input_files(
        generated = extra_generated,
        resource_bundles = None,
        transitive_infos = transitive_infos,
        xccurrentversions = None,
    )

def _merge_top_level_input_files(
        *,
        avoid_deps,
        build_mode,
        label,
        platform,
        resource_info,
        transitive_infos):
    """Creates merged inputs for an unfocused top-level target.

    Args:
        avoid_deps: A `list` of the targets that already consumed resources, and
            their resources shouldn't be bundled with `target`.
        build_mode: See `xcodeproj.build_mode`.
        label: The label of the target.
        platform: A value returned from `platforms.collect`.
        resource_info: The `AppleResourceInfo` provider for the target if it is
            resource bundle consuming.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to the one returned from `input_files.collect`. The
        values potentially include the inputs of the transitive dependencies,
        via `transitive_infos` (e.g. `generated` and `extra_files`).
    """
    if resource_info:
        resources_result = collect_resources(
            build_mode = build_mode,
            platform = platform,
            resource_info = resource_info,
            avoid_resource_infos = [
                dep[AppleResourceInfo]
                for dep in avoid_deps
                if AppleResourceInfo in dep
            ],
        )

        generated = resources_result.generated
        resource_bundles = resources_result.bundles

        xccurrentversions = resources_result.xccurrentversions
        if xccurrentversions:
            xccurrentversions = [(label, tuple(xccurrentversions))]
    else:
        generated = None
        resource_bundles = None
        xccurrentversions = None

    return _inner_merge_input_files(
        generated = generated,
        resource_bundles = resource_bundles,
        transitive_infos = transitive_infos,
        xccurrentversions = xccurrentversions,
    )

# Output groups

def _collect_bwx_output_groups(
        *,
        build_mode = None,
        id,
        modulemaps = [],
        params_files = [],
        target_inputs,
        transitive_infos):
    should_produce_output_groups = build_mode == "xcode"

    if should_produce_output_groups:
        if modulemaps:
            modulemaps = [f for f in modulemaps if not f.is_source]
            modulemaps_depset = memory_efficient_depset(modulemaps)
        else:
            modulemaps_depset = memory_efficient_depset(
                transitive = [
                    info.bwx_output_groups._modulemaps
                    for info in transitive_infos
                ],
            )

        # Purposeful flattening to work around large BEP issue.
        # This is because we only get modulemaps already flattened. Ideally we
        # would get a `depset` for the modulemaps, so they would be properly
        # represented in the BEP.
        modulemaps = modulemaps_depset.to_list()

        compiling_files = memory_efficient_depset(
            params_files + modulemaps,
            transitive = [target_inputs.generated],
        )

        compiling_output_group_name = "xc {}".format(id)
        linking_output_group_name = "xl {}".format(id)

        direct_group_list = [
            (compiling_output_group_name, compiling_files),
            (linking_output_group_name, EMPTY_DEPSET),
        ]
    else:
        direct_group_list = None
        modulemaps_depset = EMPTY_DEPSET

        if params_files:
            compiling_files = memory_efficient_depset(
                params_files,
                transitive = [target_inputs.generated],
            )
        else:
            compiling_files = target_inputs.generated

    return struct(
        _modulemaps = modulemaps_depset,
        _output_group_list = memory_efficient_depset(
            direct_group_list,
            transitive = [
                info.inputs._output_group_list
                for info in transitive_infos
            ],
        ) if should_produce_output_groups else EMPTY_DEPSET,
        compiling_files = compiling_files,
    )

def _merge_bwx_output_groups(*, transitive_infos):
    """Creates merged BwX output groups.

    Args:
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to the one returned from `bwx_output_groups.collect`.
    """
    return struct(
        _modulemaps = memory_efficient_depset(
            transitive = [
                info.bwx_output_groups._modulemaps
                for info in transitive_infos
            ],
        ),
        _output_group_list = memory_efficient_depset(
            transitive = [
                info.bwx_output_groups._output_group_list
                for info in transitive_infos
            ],
        ),
    )

def _process_output_group_files(
        *,
        files,
        output_group_name,
        additional_bwx_generated):
    # `list` copy is needed for some reason to prevent depset from changing
    # underneath us. Without this it's nondeterministic which files are in it.
    generated_depsets = list(
        additional_bwx_generated.get(output_group_name, []),
    )
    return memory_efficient_depset(
        transitive = generated_depsets + [files],
    )

def _bwx_to_output_groups_fields(
        *,
        bwx_output_groups,
        additional_bwx_generated = {},
        index_import):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        bwx_output_groups: A value returned from `bwx_output_groups.collect`.
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
            output_group_name = name,
            additional_bwx_generated = additional_bwx_generated,
            index_import = index_import,
        )
        for name, files in bwx_output_groups._output_group_list.to_list()
    }

    output_groups["all_xc"] = memory_efficient_depset(
        transitive = [
            files
            for name, files in output_groups.items()
            if name.startswith("xc ")
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
    collect_unsupported = _collect_unsupported_input_files,
    merge = _merge_input_files,
    merge_top_level = _merge_top_level_input_files,
)

bwx_output_groups = struct(
    collect = _collect_bwx_output_groups,
    merge = _merge_bwx_output_groups,
    to_output_groups_fields = _bwx_to_output_groups_fields,
)
