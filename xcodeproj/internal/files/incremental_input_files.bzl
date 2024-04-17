"""Module containing functions dealing with target input files."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceInfo",
)
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_LIST",
    "memory_efficient_depset",
)
load("//xcodeproj/internal:xcodeprojinfo.bzl", "XcodeProjInfo")
load(":incremental_resources.bzl", resources_module = "incremental_resources")
load(":linker_input_files.bzl", "linker_input_files")

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

def _collect_transitive_uncategorized(info):
    if info.xcode_target:
        return EMPTY_DEPSET
    return info.inputs._uncategorized

def _inner_merge_input_files(
        *,
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
        _resource_bundle_uncategorized_files = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_uncategorized_files
                for info in transitive_infos
            ],
        ),
        _resource_bundle_uncategorized_folders = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_uncategorized_folders
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
        _uncategorized = memory_efficient_depset(
            transitive = [
                info.inputs._uncategorized
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

def _process_files_and_deps(
        *,
        additional_src_files,
        additional_src_file_handler,
        attrs,
        collect_uncategorized,
        file_handlers,
        rule_attr,
        rule_file,
        rule_files):
    uncategorized = []
    xccurrentversions = []

    # buildifier: disable=uninitialized
    def _handle_file(file, *, handler):
        if file == None:
            return

        if handler:
            handler(file)
            categorized = True
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
                    uncategorized.append(file)

    transitive_extra_files = []

    # buildifier: disable=uninitialized
    def _handle_dep(dep):
        # This allows the transitive uncategorized files for target of a
        # categorized attribute to be included in the project
        if XcodeProjInfo not in dep:
            return
        transitive_extra_files.append(
            dep[XcodeProjInfo].inputs._uncategorized,
        )

    for attr in dir(rule_files):
        if _should_ignore_input_attr(attr):
            continue

        handler = file_handlers.get(attr, None)

        if not collect_uncategorized and not handler:
            continue

        for file in getattr(rule_files, attr):
            _handle_file(file, handler = handler)

    for attr in dir(rule_file):
        if _should_ignore_input_attr(attr):
            continue

        handler = file_handlers.get(attr, None)

        if not collect_uncategorized and not handler:
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

    return (
        transitive_extra_files,
        uncategorized,
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

def _collect_incremental_input_files(
        *,
        ctx,
        attrs,
        automatic_target_info,
        avoid_deps = EMPTY_LIST,
        framework_files = EMPTY_DEPSET,
        focused_labels = EMPTY_DEPSET,
        infoplist = None,
        label,
        linker_inputs,
        platform,
        resource_info = None,
        rule_attr,
        swift_proto_info,
        transitive_infos):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            the target.
        avoid_deps: A `list` of the targets that already consumed resources, and
            their resources shouldn't be bundled with the target.
        framework_files: A `depset` of framework files from
            `AppleDynamicFramework.framework_files`, if the target has the
            `AppleDynamicFramework` provider.
        focused_labels: A `depset` of label strings of focused targets. This
            will include the current target (if focused) and any focused
            dependencies of the current target. This is only set for top-level
            targets.
        infoplist: A `File` for a rules_xcodeproj modified Info.plist file, or
            None for non-top-level targets.
        label: The effective label of the target.
        linker_inputs: A value from `linker_file_inputs.collect`.
        platform: A value from `platforms.collect`.
        resource_info: If the target is a bundle and has the `AppleResourceInfo`
            provider, this is the provider.
        rule_attr: `ctx.rule.attr`.
        swift_proto_info: The `SwiftProtoInfo` provider for the target, or
            `None` if it doesn't have one.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the target.

    Returns:
        A `tuple` with two elements:

        *   A `struct`, which will only be used within the aspect, with the
            following fields:

            *   `c_sources`: A set `dict` (`None` values) of C source file path
                strings.
            *   `cxx_sources`: A set `dict` (`None` values) of C++ source file
                path strings.
            *   `entitlements`: A `File` for the entitlements file of `target`,
                or `None` if it doesn't have one.
            *   `xcode_inputs`: A `struct`, which will be passed to
                `xcode_targets.make`, with the following fields:

                *   `extra_file_paths`: A `depset` of file path strings that
                    aren't covered under the other attributes, but should be
                    included in the project navigator.
                *   `extra_files`: A `depset` of `File` that aren't covered
                    under the other attributes, but should be included in the
                    project navigator.
                *   `extra_folders`: A `depset` of folder path strings that
                    aren't covered under the other attributes, but should be
                    included in the project navigator.
                *   `non_arc_srcs`: A `list` of `File`s that are inputs to
                    `target`'s `non_arc_srcs`-like attributes.
                *   `srcs`: A `list` of `File`s that are inputs to `target`'s
                    `srcs`-like attributes.

        *   A `struct`, which will end up in `XcodeProjInfo.inputs`, with the
            following fields:

            *   `important_generated`: A `depset` of important generated `File`s
                that are inputs to `target` or its transitive dependencies.
                These differ from `generated` in that they will be generated as
                part of project generation, to ensure they are created before
                Xcode is opened. Entitlements are an example of this, as Xcode
                won't even start a build if they are missing.
            *   `resource_bundles`: A `depset` of values from
                `resources.collect().bundles`.
            *   `unsupported_extra_files`: A `depset` of `File`s that are inputs
                of unsupported targets. These should be included in the project
                navigator.
            *   `xccurrentversions`: A `depset` of `.xccurrentversion` `File`s
                that are in `resources`.
    """
    entitlements = []
    c_sources = {}
    cxx_sources = {}
    non_arc_srcs = []
    srcs = []

    extra_files = [infoplist] if infoplist else []

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

    for attr in automatic_target_info.extra_files:
        file_handlers[attr] = _handle_extrafiles_file
    for attr in automatic_target_info.srcs:
        file_handlers[attr] = _handle_srcs_file
    for attr in automatic_target_info.non_arc_srcs:
        file_handlers[attr] = _handle_non_arc_srcs_file
    if automatic_target_info.entitlements:
        file_handlers[automatic_target_info.entitlements] = (
            _handle_entitlements_file
        )

    if swift_proto_info:
        additional_src_files = swift_proto_info.pbswift_files.to_list()
    else:
        additional_src_files = EMPTY_LIST

    (
        transitive_extra_files,
        uncategorized,
        xccurrentversions,
    ) = _process_files_and_deps(
        additional_src_files = additional_src_files,
        additional_src_file_handler = _handle_srcs_file,
        attrs = attrs,
        collect_uncategorized = (
            automatic_target_info.collect_uncategorized_files
        ),
        file_handlers = file_handlers,
        rule_attr = rule_attr,
        rule_file = ctx.rule.file,
        rule_files = ctx.rule.files,
    )

    product_framework_files = memory_efficient_depset(
        transitive = [
            info.inputs._product_framework_files
            for info in transitive_infos
        ] + ([framework_files] if framework_files else []),
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
        extra_files.extend(linker_input_additional_files)

    if resource_info:
        resources_result = resources_module.collect(
            avoid_resource_infos = [
                dep[AppleResourceInfo]
                for dep in avoid_deps
                if AppleResourceInfo in dep
            ],
            label_str = str(label),
            focused_labels = focused_labels,
            platform = platform,
            resource_info = resource_info,
        )

        extra_files.extend(resources_result.resources)
        resource_bundles = resources_result.bundles

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
        bundle_labels = {
            label: None
            for label in resource_bundle_labels.to_list()
        }

        resource_bundle_uncategorized_files = EMPTY_DEPSET
        transitive_extra_files = [
            d
            for label, d in depset(
                transitive = [
                    info.inputs._resource_bundle_uncategorized_files
                    for info in transitive_infos
                ],
            ).to_list()
            if label not in bundle_labels
        ]

        resource_bundle_uncategorized_folders = EMPTY_DEPSET
        extra_folders = memory_efficient_depset(
            resources_result.folder_resources,
            transitive = [
                d
                for label, d in depset(
                    transitive = [
                        info.inputs._resource_bundle_uncategorized_folders
                        for info in transitive_infos
                    ],
                ).to_list()
                if label not in bundle_labels
            ],
        )
    else:
        extra_folders = EMPTY_DEPSET
        resource_bundle_labels = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_labels
                for info in transitive_infos
            ],
        )
        resource_bundle_uncategorized_files = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_uncategorized_files
                for info in transitive_infos
            ],
        )
        resource_bundle_uncategorized_folders = memory_efficient_depset(
            transitive = [
                info.inputs._resource_bundle_uncategorized_folders
                for info in transitive_infos
            ],
        )
        resource_bundles = None

    important_generated = [
        file
        for file in entitlements
        if not file.is_source
    ]

    return (
        struct(
            c_sources = c_sources,
            cxx_sources = cxx_sources,
            entitlements = entitlements[0] if entitlements else None,
            xcode_inputs = struct(
                extra_file_paths = memory_efficient_depset(extra_file_paths),
                extra_files = memory_efficient_depset(
                    extra_files,
                    transitive = transitive_extra_files,
                ),
                extra_folders = extra_folders,
                infoplist = infoplist,
                non_arc_srcs = memory_efficient_depset(non_arc_srcs),
                srcs = memory_efficient_depset(srcs),
            ),
        ),
        struct(
            _product_framework_files = product_framework_files,
            _resource_bundle_labels = resource_bundle_labels,
            _resource_bundle_uncategorized_files = (
                resource_bundle_uncategorized_files
            ),
            _resource_bundle_uncategorized_folders = (
                resource_bundle_uncategorized_folders
            ),
            _uncategorized = memory_efficient_depset(
                uncategorized,
                transitive = [
                    _collect_transitive_uncategorized(info)
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
                important_generated,
                transitive = [
                    info.inputs.important_generated
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
        ),
    )

def _collect_unsupported_input_files(
        *,
        ctx,
        attrs,
        automatic_target_info,
        include_extra_files,
        is_resource_bundle,
        label,
        rule_attr,
        transitive_infos):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        include_extra_files: Whether to include extra files in the inputs.
        is_resource_bundle: Whether `target` is a resource bundle.
        label: The effective label of the target.
        rule_attr: `ctx.rule.attr`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of `target`.

    Returns:

    A value similar to the second `struct` returned by `input_files.collect`.
    """
    extra_file_paths = []
    extra_files = []

    if include_extra_files:
        if not label.workspace_root:
            # Include BUILD files for the project but not for external repos
            extra_file_paths.append(ctx.build_file_path)

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
    for attr in automatic_target_info.extra_files:
        file_handlers[attr] = _handle_extrafiles_file

    (
        transitive_extra_files,
        uncategorized,
        xccurrentversions,
    ) = _process_files_and_deps(
        additional_src_files = EMPTY_LIST,
        additional_src_file_handler = None,
        attrs = attrs,
        collect_uncategorized = (
            include_extra_files and
            automatic_target_info.collect_uncategorized_files
        ),
        file_handlers = file_handlers,
        rule_attr = rule_attr,
        rule_file = ctx.rule.file,
        rule_files = ctx.rule.files,
    )

    if is_resource_bundle:
        uncategorized_files = []
        uncategorized_folders = []

        def _process_uncategorized_resource(resource):
            # If a file is a child of a folder-type file, the parent
            # folder-type file should be collected instead of the child file
            folder_type_prefix = resources_module.folder_type_prefix(resource)
            if folder_type_prefix:
                uncategorized_folders.append(folder_type_prefix)
                return
            uncategorized_files.append(resource)

        for file in uncategorized:
            _process_uncategorized_resource(file)

        if uncategorized_files:
            resource_bundle_uncategorized_files = [
                (
                    label,
                    memory_efficient_depset(uncategorized_files),
                ),
            ]
        else:
            resource_bundle_uncategorized_files = None

        if uncategorized_folders:
            resource_bundle_uncategorized_folders = [
                (
                    label,
                    memory_efficient_depset(uncategorized_folders),
                ),
            ]
        else:
            resource_bundle_uncategorized_folders = None
        uncategorized = None
    else:
        resource_bundle_uncategorized_files = None
        resource_bundle_uncategorized_folders = None

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
        _resource_bundle_uncategorized_files = memory_efficient_depset(
            resource_bundle_uncategorized_files,
            transitive = [
                info.inputs._resource_bundle_uncategorized_files
                for info in transitive_infos
            ],
        ),
        _resource_bundle_uncategorized_folders = memory_efficient_depset(
            resource_bundle_uncategorized_folders,
            transitive = [
                info.inputs._resource_bundle_uncategorized_folders
                for info in transitive_infos
            ],
        ),
        _uncategorized = memory_efficient_depset(
            uncategorized,
            transitive = [
                _collect_transitive_uncategorized(info)
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
        unsupported_extra_files = memory_efficient_depset(
            extra_files,
            transitive = [
                info.inputs.unsupported_extra_files
                for info in transitive_infos
            ] + (transitive_extra_files if include_extra_files else []),
        ),
        xccurrentversions = memory_efficient_depset(
            xccurrentversions,
            transitive = [
                info.inputs.xccurrentversions
                for info in transitive_infos
            ],
        ),
    )

def _merge_input_files(*, transitive_infos):
    """Creates merged inputs.

    Args:
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to the one returned from `input_files.collect`. The
        values potentially include the inputs of the transitive dependencies,
        via `transitive_infos` (e.g. `extra_files`).
    """
    return _inner_merge_input_files(
        resource_bundles = None,
        transitive_infos = transitive_infos,
        xccurrentversions = None,
    )

def _merge_top_level_input_files(
        *,
        avoid_deps,
        focused_labels,
        platform,
        resource_info,
        transitive_infos):
    """Creates merged inputs for an unfocused top-level target.

    Args:
        avoid_deps: A `list` of the targets that already consumed resources, and
            their resources shouldn't be bundled with `target`.
        focused_labels: A `depset` of label strings of focused targets. This
            will include the current target (if focused) and any focused
            dependencies of the current target.
        platform: A value from `platforms.collect`.
        resource_info: The `AppleResourceInfo` provider for the target if it is
            resource bundle consuming.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to the one returned from `input_files.collect`. The
        values potentially include the inputs of the transitive dependencies,
        via `transitive_infos` (e.g. `extra_files`).
    """
    if resource_info:
        resources_result = resources_module.collect(
            avoid_resource_infos = [
                dep[AppleResourceInfo]
                for dep in avoid_deps
                if AppleResourceInfo in dep
            ],
            focused_labels = focused_labels,
            label_str = None,
            platform = platform,
            resource_info = resource_info,
        )

        resource_bundles = resources_result.bundles

        xccurrentversions = resources_result.xccurrentversions
    else:
        resource_bundles = None
        xccurrentversions = None

    return _inner_merge_input_files(
        resource_bundles = resource_bundles,
        transitive_infos = transitive_infos,
        xccurrentversions = xccurrentversions,
    )

incremental_input_files = struct(
    collect = _collect_incremental_input_files,
    collect_unsupported = _collect_unsupported_input_files,
    merge = _merge_input_files,
    merge_top_level = _merge_top_level_input_files,
)
