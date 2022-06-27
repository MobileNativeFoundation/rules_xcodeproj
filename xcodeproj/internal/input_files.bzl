"""Module containing functions dealing with target input files."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceInfo",
)
load(":collections.bzl", "set_if_true")
load(
    ":files.bzl",
    "file_path",
    "file_path_to_dto",
    "parsed_file_path",
)
load(":output_group_map.bzl", "output_group_map")
load(":providers.bzl", "XcodeProjInfo")
load(":resources.bzl", "collect_resources")

# Utility

def _collect_transitive_extra_files(info):
    inputs = info.inputs
    transitive = [inputs.extra_files]
    if not info.target:
        transitive.append(depset([
            file_path(file)
            for file in inputs.srcs.to_list()
        ]))
        transitive.append(depset([
            file_path(file)
            for file in inputs.non_arc_srcs.to_list()
        ]))
        transitive.append(depset([
            file_path(file)
            for file in inputs.hdrs.to_list()
        ]))

    return depset(transitive = transitive)

def _collect_transitive_uncategorized(info):
    if info.target:
        return depset()
    return info.inputs.uncategorized

def _should_ignore_attr(attr):
    return (
        # We don't want to include implicit dependencies
        attr.startswith("_") or
        # These are actually Starklark methods, so ignore them
        attr in ("to_json", "to_proto")
    )

_BUNDLE_EXTENSIONS = [
    ".bundle",
    ".framework",
    ".xcframework",
]

def _normalized_file_path(file):
    path = file.path

    for extension in _BUNDLE_EXTENSIONS:
        prefix, ext, _ = path.partition(extension)
        if not ext:
            continue
        return file_path(
            file,
            path = prefix + ext,
        )

    return file_path(file)

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
    else:
        return False

def _process_cc_info_headers(headers, *, pch):
    return [
        header
        for header in headers
        if (header.is_source and
            ".framework" not in header.path and
            header not in pch)
    ]

# API

def _collect(
        *,
        ctx,
        target,
        platform,
        bundle_resources,
        is_bundle,
        automatic_target_info,
        additional_files = [],
        transitive_infos,
        avoid_deps):
    """Collects all of the inputs of a target.

    Args:
        ctx: The aspect context.
        target: The `Target` to collect inputs from.
        platform: A value returned from `platform_info.collect`.
        bundle_resources: Whether resources will be bundled in the generated
            project. If this is `False` then all resources will get added to
            `extra_files` instead of `resources`.
        is_bundle: Whether `target` is a bundle.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        additional_files: A `list` of `File`s to add to the inputs. This can
            be used to add files to the `generated` and `extra_files` fields
            (e.g. modulemaps or BUILD files).
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of `target`.
        avoid_deps: A `list` pf the targets that already consumed resources, and
            their resources shouldn't be bundled with `target`.

    Returns:
        A `struct` with the following fields:

        *   `srcs`: A `depset` of `File`s that are inputs to `target`'s
            `srcs`-like attributes.
        *   `hdrs`: A `depset` of `File`s that are inputs to `target`'s
            `hdrs`-like attributes.
        *   `non_arc_srcs`: A `depset` of `File`s that are inputs to
            `target`'s `non_arc_srcs`-like attributes.
        *   `resources`: A `depset` of `FilePath`s that are inputs to `target`'s
            `resources`-like and `structured_resources`-like attributes.
        *   `xccurrentversions`: A `depset` of `.xccurrentversion` `File`s that
            are in `resources`.
        *   `generated`: A `depset` of generated `File`s that are inputs to
            `target` or its transitive dependencies.
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

    srcs = []
    non_arc_srcs = []
    hdrs = []
    pch = []
    entitlements = []
    generated = []
    extra_files = []
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
            if file.is_source:
                # We don't need to include a generated one, as we already use
                # the Bazel generated one, which is one step further generated
                extra_files.append(file_path(file))
        elif attr == automatic_target_info.entitlements:
            # We use `append` instead of setting a single value because
            # assigning to `entitlements` creates a new local variable instead
            # of assigning to the existing variable
            entitlements.append(file)
        else:
            categorized = False

        if file.is_source:
            if not categorized and file not in output_files:
                uncategorized.append(_normalized_file_path(file))
        elif categorized:
            generated.append(file)

    transitive_extra_files = []

    # buildifier: disable=uninitialized
    def _handle_dep(dep, *, attr):
        if (XcodeProjInfo not in dep or
            not _is_categorized_attr(
                attr,
                automatic_target_info = automatic_target_info,
            )):
            return
        transitive_extra_files.append(dep[XcodeProjInfo].inputs.uncategorized)

    for attr in dir(ctx.rule.files):
        if _should_ignore_attr(attr):
            continue
        for file in getattr(ctx.rule.files, attr):
            _handle_file(file, attr = attr)

    for attr in dir(ctx.rule.file):
        if _should_ignore_attr(attr):
            continue
        _handle_file(getattr(ctx.rule.file, attr), attr = attr)

    for attr in dir(ctx.rule.attr):
        if _should_ignore_attr(attr):
            continue
        dep = getattr(ctx.rule.attr, attr, None)
        if type(dep) == "Target":
            _handle_dep(dep, attr = attr)
        elif type(dep) == "list":
            for dep in dep:
                if type(dep) == "Target":
                    _handle_dep(dep, attr = attr)

    generated.extend([file for file in additional_files if not file.is_source])
    for file in additional_files:
        extra_files.append(file_path(file))

    resources = None
    resource_bundles = None
    resource_bundle_dependencies = None
    xccurrentversions = None
    if is_bundle and AppleResourceInfo in target:
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
                bundle.resources
                for bundle in resources_result.bundles
            ])

    # Generically handle CcInfo providing rules. This allows us to pick up
    # headers from `objc_import` and the like.
    if CcInfo in target:
        compilation_context = target[CcInfo].compilation_context
        srcs.extend(
            _process_cc_info_headers(
                compilation_context.direct_private_headers,
                pch = pch,
            ),
        )
        hdrs.extend(
            _process_cc_info_headers(
                (compilation_context.direct_public_headers +
                 compilation_context.direct_textual_headers),
                pch = pch,
            ),
        )

    return struct(
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
        xccurrentversions = depset(
            xccurrentversions,
            transitive = [
                info.inputs.xccurrentversions
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        ),
        generated = depset(
            generated if generated else None,
            transitive = [
                info.inputs.generated
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        ),
        extra_files = depset(
            extra_files,
            transitive = [
                _collect_transitive_extra_files(info)
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ] + transitive_extra_files,
        ),
        uncategorized = depset(
            uncategorized,
            transitive = [
                _collect_transitive_uncategorized(info)
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        ),
    )

def _from_resource_bundle(bundle):
    return struct(
        srcs = depset(),
        non_arc_srcs = depset(),
        hdrs = depset(),
        pch = None,
        resources = bundle.resources,
        resource_bundles = depset(),
        resource_bundle_dependencies = bundle.dependencies,
        infoplists = depset(),
        entitlements = None,
        xccurrentversions = depset(),
        generated = depset(),
        extra_files = depset(),
        uncategorized = depset(),
    )

def _merge(*, transitive_infos, extra_generated = None):
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
    )

def _to_dto(inputs):
    """Generates a target DTO value for inputs.

    Args:
        inputs: A value returned from `input_files.collect`.

    Returns:
        A `dict` containing the following elements:

        *   `srcs`: A `list` of `FilePath`s for `srcs`.
        *   `non_arc_srcs`: A `list` of `FilePath`s for `non_arc_srcs`.
        *   `hdrs`: A `list` of `FilePath`s for `hdrs`.
        *   `pch`: An optional `FilePath` for `pch`.
        *   `resources`: A `list` of `FilePath`s for `resources`.
        *   `entitlements`: An optional `FilePath` for `entitlements`.
    """
    ret = {}

    def _process_attr(attr):
        value = getattr(inputs, attr)
        if value:
            ret[attr] = [
                file_path_to_dto(file_path(file))
                for file in value.to_list()
            ]

    _process_attr("srcs")
    _process_attr("non_arc_srcs")
    _process_attr("hdrs")

    if inputs.pch:
        ret["pch"] = file_path_to_dto(file_path(inputs.pch))

    if inputs.entitlements:
        ret["entitlements"] = file_path_to_dto(file_path(inputs.entitlements))

    if inputs.resources:
        set_if_true(
            ret,
            "resources",
            [file_path_to_dto(fp) for fp in inputs.resources.to_list()],
        )

    return ret

def _to_output_groups_fields(
        *,
        ctx,
        inputs,
        toplevel_cache_buster,
        configuration):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        ctx: The rule context.
        inputs: A value returned from `input_files.collect`.
        toplevel_cache_buster: A `list` of `File`s that change with each build,
            and are used as inputs to the output map generation, to ensure that
            the files references by the output map are always downloaded from
            the remote cache, even when using `--remote_download_toplevel`.
        configuration: The configuration identifier (see "configuration.bzl"'s
            `get_configuration`) for the project.

    Returns:
        A `dict` where the keys are output group names and the values are
        `depset` of `File`s.
    """
    name = "generated_inputs {}".format(configuration)
    return {
        name: depset([output_group_map.write_map(
            ctx = ctx,
            name = name,
            files = inputs.generated,
            toplevel_cache_buster = toplevel_cache_buster,
        )]),
    }

input_files = struct(
    collect = _collect,
    from_resource_bundle = _from_resource_bundle,
    merge = _merge,
    to_dto = _to_dto,
    to_output_groups_fields = _to_output_groups_fields,
)
