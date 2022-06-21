"""Module containing functions dealing with target output files."""

load(":files.bzl", "file_path", "file_path_to_dto")
load(":output_group_map.bzl", "output_group_map")

# Utility

def _create(
        *,
        direct_outputs = None,
        attrs_info = None,
        transitive_infos,
        should_produce_dto = False):
    """Creates the internal data structure of the `output_files` module.

    Args:
        direct_outputs: A value returned from `_get_outputs`, or `None` if
            the outputs are being merged.
        attrs_info: The `InputFileAttributesInfo` for the target.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.
        should_produce_dto: If `True`, `outputs_files.to_dto` will return
            collected values. This only be `True` if the generator can use
            the output files (e.g. Build with Bazel, or Focused Projects).

    Returns:
        A `struct` representing the internal data structure of the
        `output_files` module.
    """
    if direct_outputs:
        direct_build = []
        direct_index = []

        swift = direct_outputs.swift_module
        if swift:
            # TODO: Determine which of these are actually needed for each
            direct_build.append(swift.swiftdoc)
            direct_index.append(swift.swiftdoc)
            direct_build.append(swift.swiftmodule)
            direct_index.append(swift.swiftmodule)
            direct_build.append(swift.swiftsourceinfo)
            direct_index.append(swift.swiftsourceinfo)
            if swift.swiftinterface:
                direct_build.append(swift.swiftinterface)
                direct_index.append(swift.swiftinterface)

        if direct_outputs.swift_generated_header:
            direct_build.append(direct_outputs.swift_generated_header)
            direct_index.append(direct_outputs.swift_generated_header)

        if direct_outputs.product:
            direct_build.append(direct_outputs.product)
    else:
        direct_build = None
        direct_index = None

    transitive_build = depset(
        direct_build,
        transitive = [
            info.outputs._transitive_build
            for attr, info in transitive_infos
            if (not attrs_info or
                info.target_type in attrs_info.xcode_targets.get(attr, [None]))
        ],
    )

    transitive_index = depset(
        direct_index,
        transitive = [
            info.outputs._transitive_index
            for attr, info in transitive_infos
            if (not attrs_info or
                info.target_type in attrs_info.xcode_targets.get(attr, [None]))
        ],
    )

    if direct_outputs:
        direct_group_list = [
            ("b {}".format(direct_outputs.id), transitive_build),
            ("i {}".format(direct_outputs.id), transitive_index),
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
        _direct_outputs = direct_outputs if should_produce_dto else None,
        _output_group_list = output_group_list,
        _transitive_build = transitive_build,
        _transitive_index = transitive_index,
    )

def _get_outputs(*, target_files, bundle_info, id, default_info, swift_info):
    """Collects the output files for a given target.

    The outputs are bucketed into two categories: build and index. The build
    category contains the files that are needed by Xcode to build, run, or test
    a target. The index category contains files that are needed by Xcode's
    indexing process.

    Args:
        target_files: The `files` attribute of the target. This should be `[]`
            if `bundle_info` is not `None`.
        bundle_info: The `AppleBundleInfo` provider for the target, or `None`.
        id: The unique identifier of the target.
        default_info: The `DefaultInfo` provider for the target, or `None`.
        swift_info: The `SwiftInfo` provider for the target, or `None`.

    Returns:
        A `struct` containing the following fields:

        *   `id`: The unique identifier of the target.
        *   `bundle`: A `File` for the target's bundle (e.g. ".app") or `None`.
        *   `swift_generated_header`: A `File` for the generated Swift header
            file, or `None`.
        *   `swift_module`: A value as returned by
            `swift_common.create_swift_module`, or `None`.
    """

    # TODO: Deduplicate work here and in `_process_top_level_target`.
    xctest = None
    for file in target_files:
        if ".xctest/" in file.short_path:
            xctest = file
            break

    product_file_path = None
    if bundle_info:
        product = bundle_info.archive
    elif xctest:
        product = xctest

        # "some/test.xctest/binary" -> "some/test.xctest"
        xctest_path = xctest.path
        product_file_path = file_path(
            xctest,
            path = xctest_path[:-(len(xctest_path.split(".xctest/")[1]) + 1)],
        )
    elif default_info and default_info.files_to_run.executable:
        product = default_info.files_to_run.executable
    else:
        product = None

    if product and not product_file_path:
        product_file_path = file_path(product)

    swift_generated_header = None
    swift_module = None
    if swift_info:
        # TODO: Actually handle more than one module?
        for module in swift_info.direct_modules:
            swift = module.swift
            if not swift:
                continue
            swift_module = swift
            clang = module.clang
            if clang.compilation_context.direct_public_headers:
                swift_generated_header = (
                    clang.compilation_context.direct_public_headers[0]
                )
            break

    return struct(
        id = id,
        product = product,
        product_file_path = product_file_path,
        swift_generated_header = swift_generated_header,
        swift_module = swift_module,
    )

def _swift_to_dto(generated_header, module):
    dto = {
        "m": file_path_to_dto(file_path(module.swiftmodule)),
        "s": file_path_to_dto(file_path(module.swiftsourceinfo)),
        "d": file_path_to_dto(file_path(module.swiftdoc)),
    }

    if module.swiftinterface:
        dto["i"] = file_path_to_dto(file_path(module.swiftinterface))

    if generated_header:
        dto["h"] = file_path_to_dto(file_path(generated_header))

    return dto

# API

def _collect(
        *,
        target_files,
        bundle_info,
        default_info,
        swift_info,
        id,
        transitive_infos,
        should_produce_dto):
    """Collects the outputs of a target.

    Args:
        bundle_info: The `AppleBundleInfo` provider for  the target, or `None`.
        default_info: The `DefaultInfo` provider for the target, or `None`.
        swift_info: The `SwiftInfo` provider for the target, or `None`.
        id: A unique identifier for the target.
        target_files: The `files` attribute of the target. This should be `[]`
            if `bundle_info` is not `None`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the target.
        should_produce_dto: If `True`, `outputs_files.to_dto` will return
            collected values. This only be `True` if the generator can use
            the output files (e.g. Build with Bazel, or Focused Projects).

    Returns:
        An opaque `struct` that should be used with `output_files.to_dto` or
        `output_files.to_output_groups_fields`.
    """
    outputs = _get_outputs(
        target_files = target_files,
        bundle_info = bundle_info,
        id = id,
        default_info = default_info,
        swift_info = swift_info,
    )

    return _create(
        direct_outputs = outputs,
        should_produce_dto = should_produce_dto,
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

def _to_dto(outputs):
    direct_outputs = outputs._direct_outputs
    if not direct_outputs:
        return {}

    dto = {}

    if direct_outputs.product:
        dto["p"] = file_path_to_dto(direct_outputs.product_file_path)

    if direct_outputs.swift_module:
        dto["s"] = _swift_to_dto(
            generated_header = direct_outputs.swift_generated_header,
            module = direct_outputs.swift_module,
        )

    return dto

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
            name = name.replace("/", "_"),
            files = files,
            toplevel_cache_buster = toplevel_cache_buster,
        )])
        for name, files in outputs._output_group_list.to_list()
    }

output_files = struct(
    collect = _collect,
    merge = _merge,
    to_dto = _to_dto,
    to_output_groups_fields = _to_output_groups_fields,
)
