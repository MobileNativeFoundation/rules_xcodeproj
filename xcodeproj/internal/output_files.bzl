"""Module containing functions dealing with target output files."""

load(":output_group_map.bzl", "output_group_map")

# Utility

def _create(*, direct_outputs = None, attrs_info = None, transitive_infos):
    """Creates the internal data structure of the `output_files` module.

    Args:
        direct_outputs: A value returned from `_get_outputs`, or `None` if
            the outputs are being merged.
        attrs_info: The `InputFileAttributesInfo` for the target.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A `struct` representing the internal data structure of the
        `output_files` module.
    """
    build = depset(
        direct_outputs.build if direct_outputs else None,
        transitive = [
            info.outputs._build
            for attr, info in transitive_infos
            if (not attrs_info or
                info.target_type in attrs_info.xcode_targets.get(attr, [None]))
        ],
    )
    index = depset(
        direct_outputs.index if direct_outputs else None,
        transitive = [
            info.outputs._index
            for attr, info in transitive_infos
            if (not attrs_info or
                info.target_type in attrs_info.xcode_targets.get(attr, [None]))
        ],
    )

    if direct_outputs:
        direct_group_list = [
            ("b {}".format(direct_outputs.id), build),
            ("i {}".format(direct_outputs.id), index),
        ]
    else:
        direct_group_list = None

    output_group_list = depset(
        direct_group_list,
        transitive = [
            info.outputs._output_group_list
            for attr, info in transitive_infos
            if (not attrs_info or
                info.target_type in attrs_info.xcode_targets.get(attr, [None]))
        ],
    )

    return struct(
        _build = build,
        _index = index,
        _output_group_list = output_group_list,
    )

def _get_outputs(*, bundle_info, id, swift_info):
    """Collects the output files for a given target.

    The outputs are bucketed into two categories: build and index. The build
    category contains the files that are needed by Xcode to build, run, or test
    a target. The index category contains files that are needed by Xcode's
    indexing process.

    Args:
        bundle_info: The `AppleBundleInfo` provider for the target, or `None`.
        id: The unique identifier of the target.
        swift_info: The `SwiftInfo` provider for the target, or `None`.

    Returns:
        A `struct` containing the following fields:

        *   `build`: A `list` of `File`s that are needed by Xcode to build, run,
            or test the target.
        *   `id`: The unique identifier of the target.
        *   `index`: A `list` of `File`s that are needed by Xcode's indexing
            process.
    """
    build = []
    index = []

    if bundle_info:
        build.append(bundle_info.archive)

    # TODO: Collect headers for CC targets

    # TODO: Determine which of these are actually needed for build vs index
    if swift_info:
        for module in swift_info.direct_modules:
            if module.compilation_context:
                index.extend(module.compilation_context.module_maps)

            swift = module.swift
            if not swift:
                continue
            build.append(swift.swiftdoc)
            index.append(swift.swiftdoc)
            build.append(swift.swiftmodule)
            index.append(swift.swiftmodule)
            if swift.swiftinterface:
                build.append(swift.swiftinterface)
                index.append(swift.swiftinterface)

    return struct(build = build, id = id, index = index)

# API

def _collect(
        *,
        bundle_info,
        swift_info,
        id,
        transitive_infos):
    """Collects the outputs of a target.

    Args:
        bundle_info: The `AppleBundleInfo` provider for  the target, or `None`.
        swift_info: The `SwiftInfo` provider for the target, or `None`.
        id: A unique identifier for the target.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the target.

    Returns:
        An opaque `struct` that should be used with
        `output_files.to_output_groups_fields`.
    """

    # TODO: When building a static library, we probably only need direct
    #       outputs, not transitive ones. We should account for that.
    outputs = _get_outputs(
        bundle_info = bundle_info,
        id = id,
        swift_info = swift_info,
    )

    return _create(
        direct_outputs = outputs,
        transitive_infos = transitive_infos,
    )

def _merge(*, attrs_info, transitive_infos):
    """Creates merged outputs.

    Args:
        attrs_info: The `InputFileAttributesInfo` for the target.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to the one returned from `output_files.collect`. The
        values include the outputs of the transitive dependencies, via
        `transitive_infos` (e.g. `generated` and `extra_files`).
    """
    return _create(transitive_infos = transitive_infos, attrs_info = attrs_info)

def _to_output_groups_fields(*, ctx, outputs, toplevel_cache_buster):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        ctx: The rule context.
        outputs: A value returned from `output_files.collect()`.
        toplevel_cache_buster: A `list` of `File`s that change with each build,
            and are used as inputs to the output map generation, to ensure that
            the files references by the output map are always downloaded from
            the remote cache, even when using `--remote_download_toplevel`.

    Returns:
        A `dict` where the keys are output group names and the values are
        `depset` of `File`s.
    """
    return {
        name: depset([output_group_map.write_map(
            ctx = ctx,
            name = name.replace("/", "_").replace(" ", "_"),
            files = files,
            toplevel_cache_buster = toplevel_cache_buster,
        )])
        for name, files in outputs._output_group_list.to_list()
    }

output_files = struct(
    collect = _collect,
    merge = _merge,
    to_output_groups_fields = _to_output_groups_fields,
)
