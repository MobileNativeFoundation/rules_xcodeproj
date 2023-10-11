"""Module containing functions dealing with target output files."""

load("//xcodeproj/internal:indexstore_filelists.bzl", "indexstore_filelists")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_STRING",
    "memory_efficient_depset",
)

_COPYABLE_PRODUCT_TYPES = {
    "2": True,  # com.apple.product-type.xcode-extension
    "3": False,  # com.apple.product-type.metal-library
    "A": True,  # com.apple.product-type.application.on-demand-install-capable
    "B": True,  # com.apple.product-type.bundle
    "E": True,  # com.apple.product-type.extensionkit-extension
    "F": False,  # com.apple.product-type.framework.static
    "I": True,  # com.apple.product-type.instruments-package
    "L": True,  # com.apple.product-type.library.static
    "M": True,  # com.apple.product-type.application.messages
    "S": True,  # com.apple.product-type.system-extension
    "T": True,  # com.apple.product-type.tool
    "U": True,  # com.apple.product-type.bundle.ui-testing
    "W": True,  # com.apple.product-type.watchkit2-extension
    "X": True,  # com.apple.product-type.xpc-service
    "a": True,  # com.apple.product-type.application
    "b": False,  # com.apple.product-type.bundle (resource bundle)
    "c": True,  # com.apple.product-type.application.watchapp2-container
    "d": True,  # com.apple.product-type.driver-extension
    "e": True,  # com.apple.product-type.app-extension
    "f": True,  # com.apple.product-type.framework
    "i": True,  # com.apple.product-type.app-extension.intents-service
    "l": True,  # com.apple.product-type.library.dynamic
    "m": True,  # com.apple.product-type.app-extension.messages
    "o": True,  # com.apple.product-type.bundle.ocunit-test
    "s": True,  # com.apple.product-type.app-extension.messages-sticker-pack
    "t": True,  # com.apple.product-type.tv-app-extension
    "u": True,  # com.apple.product-type.bundle.unit-test
    "w": True,  # com.apple.product-type.application.watchapp2
    "x": True,  # com.apple.product-type.xcframework
}

# Utility

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
    if (_has_dsym(debug_outputs) and
        output_group_info and
        "dsyms" in output_group_info):
        dsym_files = output_group_info["dsyms"]

    if product:
        copy_output_to_xcode = _COPYABLE_PRODUCT_TYPES[product.type]
        is_framework = product.type.startswith(
            "com.apple.product-type.framework",
        )
    else:
        copy_output_to_xcode = False
        is_framework = False

    return struct(
        id = id,
        is_framework = is_framework,
        product = product.file if product else None,
        product_path = (
            product.path if product and copy_output_to_xcode else None
        ),
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
        actions,
        copy_product_transitively = False,
        debug_outputs,
        id,
        indexstore_overrides = [],
        infoplist = None,
        name,
        output_group_info,
        product = None,
        should_produce_dto = True,
        should_produce_output_groups = True,
        swift_info,
        transitive_infos):
    """Collects the outputs of a target.

    Args:
        actions: `ctx.actions`.
        copy_product_transitively: Whether or not to copy the product
            transitively. Currently this should only be true for top-level
            targets.
        debug_outputs: The `AppleDebugOutputs` provider for the target, or
            `None`.
        id: A unique identifier for the target.
        indexstore_overrides: A `list` of `(indexstore, target_name)` `tuple`s
            that override the indexstore for the target. This is used for merged
            targets.
        infoplist: A `File` or `None`.
        name: Name (potentially replaced) of the target.
        output_group_info: The `OutputGroupInfo` provider for the target, or
            `None`.
        product: A value returned from `process_product`.
        should_produce_dto: If `True`, `outputs_files.to_dto` will return
            collected values. This will only be `True` if the generator can use
            the output files (e.g. not Build with Bazel via Proxy).
        should_produce_output_groups: If `True`,
            `outputs.to_output_groups_fields` will include output groups for
            this target. This will only be `True` for modes that build primarily
            with Bazel.
        swift_info: The `SwiftInfo` provider for the target, or `None`.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the target.

    Returns:
        An opaque `struct` that should be used with `output_files.to_dto` or
        `output_files.to_output_groups_fields`.
    """
    direct_outputs = _get_outputs(
        debug_outputs = debug_outputs,
        id = id,
        output_group_info = output_group_info,
        product = product,
        swift_info = swift_info,
    )

    compiled = None
    direct_products = []
    dsym_files = EMPTY_DEPSET
    indexstore = None

    is_framework = direct_outputs.is_framework
    swift = direct_outputs.swift
    if swift:
        compiled, indexstore = swift_to_outputs(swift)

    if direct_outputs.product:
        direct_products.append(direct_outputs.product)

    if direct_outputs.dsym_files:
        dsym_files = direct_outputs.dsym_files

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

        if not indexstore_overrides and indexstore:
            indexstore_overrides = [(indexstore, EMPTY_STRING)]

        transitive_indexstore_overrides = memory_efficient_depset(
            indexstore_overrides,
            transitive = [
                info.outputs._transitive_indexstore_overrides
                for info in transitive_infos
            ],
        )
        transitive_indexstores = memory_efficient_depset(
            [indexstore] if indexstore else None,
            transitive = [
                info.outputs._transitive_indexstores
                for info in transitive_infos
            ],
        )

        # TODO: Once BwB mode no longer has target dependencies, remove
        # transitive products. Until then we need them, to allow `Copy Bazel
        # Outputs` to be able to copy the products of transitive dependencies.
        transitive_products = memory_efficient_depset(
            direct_products if copy_product_transitively else None,
            transitive = [
                info.outputs._transitive_products
                for info in transitive_infos
            ] + [dsym_files],
        )
        products_depset = memory_efficient_depset(
            direct_products if not copy_product_transitively else None,
            transitive = [transitive_products],
        )
    else:
        closest_compiled = EMPTY_DEPSET
        transitive_indexstore_overrides = EMPTY_DEPSET
        transitive_indexstores = EMPTY_DEPSET
        transitive_products = EMPTY_DEPSET
        products_depset = EMPTY_DEPSET

    transitive_infoplists = memory_efficient_depset(
        [infoplist] if infoplist else None,
        transitive = [
            info.outputs._transitive_infoplists
            for info in transitive_infos
        ],
    )

    if should_produce_output_groups:
        generated_output_group_name = "bc {}".format(direct_outputs.id)
        linking_output_group_name = "bl {}".format(direct_outputs.id)
        products_output_group_name = "bp {}".format(direct_outputs.id)

        indexstores_filelist = indexstore_filelists.write(
            actions = actions,
            indexstore_and_target_overrides = transitive_indexstore_overrides,
            indexstores = transitive_indexstores,
            name = "bi",
            rule_name = name,
        )

        # We don't want to declare indexstore files as outputs, because they
        # expand to individual files and blow up the BEP
        indexstores_files = depset([indexstores_filelist])

        compiled_and_generated_transitive = [closest_compiled]

        direct_group_list = [
            (
                "bi {}".format(direct_outputs.id),
                True,
                indexstores_files,
            ),
            (linking_output_group_name, False, EMPTY_DEPSET),
            (products_output_group_name, False, products_depset),
        ]
    else:
        generated_output_group_name = None
        linking_output_group_name = None
        products_output_group_name = None
        compiled_and_generated_transitive = None
        direct_group_list = None

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
            _transitive_indexstore_overrides = transitive_indexstore_overrides,
            _transitive_indexstores = transitive_indexstores,
            _transitive_products = transitive_products,
            _transitive_infoplists = transitive_infoplists,
        ),
        struct(
            _compiled_and_generated_transitive = (
                compiled_and_generated_transitive
            ),
            _direct_group_list = direct_group_list,
            _generated_output_group_name = generated_output_group_name,
        ),
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
    return struct(
        _closest_compiled = EMPTY_DEPSET,
        _is_framework = False,
        _transitive_indexstore_overrides = EMPTY_DEPSET,
        _transitive_indexstores = EMPTY_DEPSET,
        _transitive_products = EMPTY_DEPSET,
        _transitive_infoplists = memory_efficient_depset(
            transitive = [
                info.outputs._transitive_infoplists
                for info in transitive_infos
            ],
        ),
    )

# Output groups

def _collect_bwb_output_groups(
        *,
        bwx_output_groups,
        metadata,
        transitive_infos):
    compiled_and_generated_transitive = (
        metadata._compiled_and_generated_transitive
    )
    if compiled_and_generated_transitive:
        compiled_and_generated_transitive.append(
            bwx_output_groups.compiling_files,
        )

        direct_group_list = metadata._direct_group_list + [
            (
                metadata._generated_output_group_name,
                False,
                memory_efficient_depset(
                    transitive = compiled_and_generated_transitive,
                ),
            ),
        ]
    else:
        direct_group_list = None

    output_group_list = memory_efficient_depset(
        direct_group_list,
        transitive = [
            info.bwb_output_groups._output_group_list
            for info in transitive_infos
        ],
    )

    return struct(
        _output_group_list = output_group_list,
    )

def _merge_bwb_output_groups(*, transitive_infos):
    """Creates merged BwB output groups.

    Args:
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of the current target.

    Returns:
        A value similar to the one returned from `bwb_output_groups.collect`.
    """
    return struct(
        _output_group_list = memory_efficient_depset(
            transitive = [
                info.bwb_output_groups._output_group_list
                for info in transitive_infos
            ],
        ),
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

def _bwb_to_output_groups_fields(
        *,
        bwb_output_groups,
        additional_bwb_outputs = {},
        index_import):
    """Generates a dictionary to be splatted into `OutputGroupInfo`.

    Args:
        bwb_output_groups: A value returned from `bwb_output_groups.collect`.
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
        for name, is_indexstores, files in bwb_output_groups._output_group_list.to_list()
    }

    output_groups["all_b"] = memory_efficient_depset(
        transitive = output_groups.values(),
    )

    return output_groups

# Swift

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
        indexstore = getattr(swift, "indexstore", None),
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

    return (compiled, swift.indexstore)

output_files = struct(
    collect = _collect_output_files,
    merge = _merge_output_files,
)

bwb_output_groups = struct(
    collect = _collect_bwb_output_groups,
    merge = _merge_bwb_output_groups,
    to_output_groups_fields = _bwb_to_output_groups_fields,
)
