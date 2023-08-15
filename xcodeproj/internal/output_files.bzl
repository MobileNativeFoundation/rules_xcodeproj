"""Module containing functions dealing with target output files."""

load(":filelists.bzl", "filelists")
load(":memory_efficiency.bzl", "EMPTY_DEPSET", "memory_efficient_depset")

# Utility

def _create(
        *,
        ctx,
        direct_outputs = None,
        infoplist = None,
        inputs,
        transitive_infos,
        should_produce_dto,
        should_produce_output_groups):
    """Creates the internal data structure of the `output_files` module.

    Args:
        ctx: The aspect context.
        direct_outputs: A value returned from `_get_outputs`, or `None` if
            the outputs are being merged.
        infoplist: A `File` or `None`.
        inputs: A value returned from `input_files.collect`, or `None`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.
        should_produce_dto: If `True`, `outputs_files.to_dto` will return
            collected values. This will only be `True` if the generator can use
            the output files (e.g. not Build with Bazel via Proxy).
        should_produce_output_groups: If `True`,
            `outputs.to_output_groups_fields` will include output groups for
            this target. This will only be `True` for modes that build primarily
            with Bazel.

    Returns:
        A `tuple` with containing two elements:

        *   A `struct`, which will only be used within the aspect, with the
            following fields:

            *   `direct_outputs`
            *   `generated_output_group_name`
            *   `linking_output_group_name`
            *   `products_output_group_name`

        *   An opaque `struct`, which will end up in `XcodeProjInfo.outputs`,
            representing the internal data structure of the `output_files`
            module.
    """
    compiled = None
    direct_products = []
    dsym_files = EMPTY_DEPSET
    indexstore = None

    if direct_outputs:
        is_framework = direct_outputs.is_framework
        swift = direct_outputs.swift
        if swift:
            compiled, indexstore = swift_to_outputs(swift)

        if direct_outputs.product:
            direct_products.append(direct_outputs.product)

        if direct_outputs.dsym_files:
            dsym_files = direct_outputs.dsym_files
    else:
        is_framework = False
        swift = None

    if should_produce_output_groups:
        if compiled:
            # We only need the single swiftmodule in order to download
            # everything from the remote cache (because of
            # `--experimental_remote_download_regex`). Reducing the number of
            # items in an output group keeps the BEP small.
            closest_compiled = memory_efficient_depset(compiled[0:1])
        else:
            closest_compiled = memory_efficient_depset(transitive = [
                info.outputs._closest_compiled
                for info in transitive_infos
                if not info.outputs._is_framework
            ])

        transitive_indexestores = memory_efficient_depset(
            [indexstore] if indexstore else None,
            transitive = [
                info.outputs._transitive_indexestores
                for info in transitive_infos
            ],
        )

        # TODO: Once BwB mode no longer has target dependencies, remove
        # transitive products. Until then we need them, to allow `Copy Bazel
        # Outputs` to be able to copy the products of transitive dependencies.
        transitive_products = memory_efficient_depset(
            direct_products if direct_products else None,
            transitive = [
                info.outputs._transitive_products
                for info in transitive_infos
            ] + [dsym_files],
        )
    else:
        closest_compiled = EMPTY_DEPSET
        transitive_indexestores = EMPTY_DEPSET
        transitive_products = EMPTY_DEPSET

    transitive_infoplists = memory_efficient_depset(
        [infoplist] if infoplist else None,
        transitive = [
            info.outputs._transitive_infoplists
            for info in transitive_infos
        ],
    )

    if should_produce_output_groups and direct_outputs:
        generated_output_group_name = "bc {}".format(direct_outputs.id)
        linking_output_group_name = "bl {}".format(direct_outputs.id)
        products_output_group_name = "bp {}".format(direct_outputs.id)

        indexstores_filelist = filelists.write(
            actions = ctx.actions,
            rule_name = ctx.rule.attr.name,
            name = "bi",
            files = transitive_indexestores,
        )

        # We don't want to declare indexstore files as outputs, because they
        # expand to individual files and blow up the BEP
        indexstores_files = depset([indexstores_filelist])

        compiled_and_generated_transitive = [closest_compiled]
        if inputs:
            compiled_and_generated_transitive.append(inputs.compiling_files)

        direct_group_list = [
            (
                generated_output_group_name,
                False,
                memory_efficient_depset(
                    transitive = compiled_and_generated_transitive,
                ),
            ),
            (
                "bi {}".format(direct_outputs.id),
                True,
                indexstores_files,
            ),
            (linking_output_group_name, False, EMPTY_DEPSET),
            (products_output_group_name, False, transitive_products),
        ]
    else:
        generated_output_group_name = None
        linking_output_group_name = None
        products_output_group_name = None
        direct_group_list = None

    output_group_list = memory_efficient_depset(
        direct_group_list,
        transitive = [
            info.outputs._output_group_list
            for info in transitive_infos
        ],
    )

    return (
        struct(
            direct_outputs = direct_outputs if should_produce_dto else None,
            generated_output_group_name = generated_output_group_name,
            linking_output_group_name = linking_output_group_name,
            products_output_group_name = products_output_group_name,
            transitive_infoplists = transitive_infoplists,
        ),
        struct(
            _closest_compiled = closest_compiled,
            _is_framework = is_framework,
            _output_group_list = output_group_list,
            _transitive_indexestores = transitive_indexestores,
            _transitive_products = transitive_products,
            _transitive_infoplists = transitive_infoplists,
        ),
    )

def _get_outputs(*, debug_outputs, id, product, swift_info, output_group_info):
    """Collects the output files for a given target.

    The outputs are bucketed into two categories: build and index. The build
    category contains the files that are needed by Xcode to build, run, or test
    a target. The index category contains files that are needed by Xcode's
    indexing process.

    Args:
        debug_outputs: The `AppleDebugOutputs` provider for the target, or
            `None`.
        id: The unique identifier of the target.
        output_group_info: The `OutputGroupInfo` provider for the target, or
            `None`.
        product: A value returned from `process_product`, or `None` if the
            target isn't a top level target.
        swift_info: The `SwiftInfo` provider for the target, or `None`.

    Returns:
        A `struct` containing the following fields:

        *   `dsym_files`: A `depset` of dSYM files or `None`.
        *   `id`: The unique identifier of the target.
        *   `product`: A `File` for the target's product (e.g. ".app" or ".zip")
            or `None`.
        *   `product_file_path`: A `file_path` for the target's product or
            `None`.
        *   `swift`: A value returned from `parse_swift_info_module`.
    """
    swift = None
    if swift_info:
        # TODO: Actually handle more than one module?
        for module in swift_info.direct_modules:
            swift = parse_swift_info_module(module)
            if swift:
                break

    # _has_dsym will be False if --apple_generate_dsym is not passed
    dsym_files = None
    if _has_dsym(debug_outputs) and output_group_info and "dsyms" in output_group_info:
        dsym_files = output_group_info["dsyms"]

    if product and product.type.startswith("com.apple.product-type.framework"):
        is_framework = True
    else:
        is_framework = False

    return struct(
        id = id,
        is_framework = is_framework,
        product = product.file if product else None,
        product_path = product.path if product else None,
        product_file_path = product.actual_file_path if product else None,
        dsym_files = dsym_files,
        swift = swift,
    )

def _has_dsym(debug_outputs):
    """Returns True if the given target provides dSYM, otherwise False."""
    if debug_outputs:
        outputs_map = debug_outputs.outputs_map
        for _, arch_outputs in outputs_map.items():
            if "dsym_binary" in arch_outputs:
                return True
    return False

# API

def _collect_output_files(
        *,
        ctx,
        debug_outputs,
        id,
        output_group_info,
        swift_info,
        top_level_product = None,
        infoplist = None,
        inputs = None,
        transitive_infos,
        should_produce_dto = True,
        should_produce_output_groups = True):
    """Collects the outputs of a target.

    Args:
        ctx: The aspect context.
        debug_outputs: The `AppleDebugOutputs` provider for the target, or
            `None`.
        id: A unique identifier for the target.
        output_group_info: The `OutputGroupInfo` provider for the target, or
            `None`.
        swift_info: The `SwiftInfo` provider for the target, or `None`.
        top_level_product: A value returned from `process_product`, or `None` if
            the target isn't a top level target.
        infoplist: A `File` or `None`.
        inputs: A value returned from `input_files.collect`, or `None`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the target.
        should_produce_dto: If `True`, `outputs_files.to_dto` will return
            collected values. This will only be `True` if the generator can use
            the output files (e.g. not Build with Bazel via Proxy).
        should_produce_output_groups: If `True`,
            `outputs.to_output_groups_fields` will include output groups for
            this target. This will only be `True` for modes that build primarily
            with Bazel.

    Returns:
        An opaque `struct` that should be used with `output_files.to_dto` or
        `output_files.to_output_groups_fields`.
    """
    if should_produce_output_groups:
        should_produce_output_groups = ctx.attr._build_mode != "xcode"

    outputs = _get_outputs(
        debug_outputs = debug_outputs,
        id = id,
        output_group_info = output_group_info,
        product = top_level_product,
        swift_info = swift_info,
    )

    return _create(
        ctx = ctx,
        direct_outputs = outputs,
        infoplist = infoplist,
        inputs = inputs,
        should_produce_dto = should_produce_dto,
        should_produce_output_groups = should_produce_output_groups,
        transitive_infos = transitive_infos,
    )

def _merge_output_files(*, transitive_infos):
    """Creates merged outputs.

    Args:
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to the one returned from `output_files.collect`. The
        values include the outputs of the transitive dependencies, via
        `transitive_infos` (e.g. `generated` and `extra_files`).
    """
    return _create(
        ctx = None,
        transitive_infos = transitive_infos,
        inputs = None,
        should_produce_dto = False,
        should_produce_output_groups = False,
    )

def _process_output_group_files(
        *,
        files,
        is_indexstores,
        output_group_name,
        additional_bwb_outputs,
        index_import):
    # `list` copy is needed for some reason to prevent depset from changing
    # underneath us. Without this it's nondeterministic which files are in it.
    outputs_depsets = list(additional_bwb_outputs.get(output_group_name, []))

    if is_indexstores:
        direct = [index_import]
    else:
        direct = None

    return memory_efficient_depset(
        direct,
        transitive = outputs_depsets + [files],
    )

def _to_output_groups_fields(
        *,
        outputs,
        additional_bwb_outputs = {},
        index_import):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        outputs: A value returned from `output_files.collect()`.
        additional_bwb_outputs: A `dict` that maps the output group name of
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
            additional_bwb_outputs = additional_bwb_outputs,
            index_import = index_import,
        )
        for name, is_indexstores, files in outputs._output_group_list.to_list()
    }

    output_groups["all_b"] = memory_efficient_depset(
        transitive = output_groups.values(),
    )

    return output_groups

def parse_swift_info_module(module):
    """Collects outputs from a rules_swift module.

    Args:
        module: A value returned from `swift_common.create_module`.

    Returns:
        A `struct` with the following fields:

        *   `swift_generated_header`: A `File` for the generated Swift header
            file, or `None`.
        *   `module`: A value returned from `swift_common.create_swift_module`.
    """
    swift = module.swift
    if not swift:
        return None

    clang = module.clang
    if clang and clang.compilation_context.direct_public_headers:
        generated_header = (
            clang.compilation_context.direct_public_headers[0]
        )
    else:
        generated_header = None

    return struct(
        module = swift,
        generated_header = generated_header,
    )

def swift_to_outputs(swift):
    """Converts a Swift output struct to more easily consumable outputs.

    Args:
        swift: A value returned from `parse_swift_info_module`.

    Returns:
        A `tuple` containing two elements:

        *   A `list` of `File`s that can be used for future compiles (e.g.
            `.swiftmodule`, `-Swift.h`).
        *   A `File`s that represent generated index store data, or `None`.
    """
    if not swift:
        return ([], None)

    module = swift.module

    # `swiftmodule` is listed first, as it's used as the "source" of the others
    compiled = [module.swiftmodule, module.swiftdoc]
    if module.swiftsourceinfo:
        compiled.append(module.swiftsourceinfo)
    if module.swiftinterface:
        compiled.append(module.swiftinterface)
    if swift.generated_header:
        compiled.append(swift.generated_header)

    return (compiled, getattr(module, "indexstore", None))

output_files = struct(
    collect = _collect_output_files,
    merge = _merge_output_files,
    to_output_groups_fields = _to_output_groups_fields,
)
