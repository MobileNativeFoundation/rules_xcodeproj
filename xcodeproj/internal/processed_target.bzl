"""Functions for creating data structures related to processed bazel targets."""

load(":files.bzl", "file_path_to_dto")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":output_files.bzl", "output_files")
load(":product.bzl", "product_to_dto")
load(":providers.bzl", "target_type")
load(":resource_bundle_products.bzl", "resource_bundle_products")

def processed_target(
        *,
        attrs_info,
        dependencies,
        inputs,
        linker_inputs,
        outputs,
        potential_target_merges,
        required_links,
        resource_bundles,
        search_paths,
        target,
        xcode_target):
    """Generates the return value for target processing functions.

    Args:
        attrs_info: The `InputFileAttributesInfo` for the target.
        dependencies: A `list` of target ids of direct dependencies of this
            target.
        inputs: A value as returned from `input_files.collect` that will
            provide values for the `XcodeProjInfo.inputs` field.
        linker_inputs: A value returned from `linker_input_files.collect`
            that will provide values for the `XcodeProjInfo.linker_inputs`
            field.
        outputs: A value as returned from `output_files.collect` that will
            provide values for the `XcodeProjInfo.outputs` field.
        potential_target_merges: An optional `list` of `struct`s that will be in
            the `XcodeProjInfo.potential_target_merges` `depset`.
        required_links: An optional `list` of strings that will be in the
            `XcodeProjInfo.required_links` `depset`.
        resource_bundles: The value returned from
            `resource_bundle_products.collect`.
        search_paths: The value returned from `_process_search_paths`.
        target: An optional `XcodeProjInfo.target` `struct`.
        xcode_target: An optional string that will be in the
            `XcodeProjInfo.xcode_targets` `depset`.

    Returns:
        A `struct` containing fields for each argument.
    """
    return struct(
        attrs_info = attrs_info,
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        outputs = outputs,
        potential_target_merges = potential_target_merges,
        required_links = required_links,
        resource_bundles = resource_bundles,
        search_paths = search_paths,
        target = target,
        target_type = target_type,
        xcode_targets = [xcode_target] if xcode_target else None,
    )

def xcode_target(
        *,
        id,
        name,
        label,
        configuration,
        package_bin_dir,
        platform,
        product,
        is_bundle,
        is_swift,
        test_host,
        avoid_infos = [],
        build_settings,
        search_paths,
        modulemaps,
        swiftmodules,
        resource_bundles,
        inputs,
        linker_inputs,
        info_plist,
        entitlements,
        dependencies,
        outputs):
    """Generates the partial json string representation of an Xcode target.

    Args:
        id: A unique identifier. No two `_xcode_target` will have the same `id`.
            This won't be user facing, the generator will use other fields to
            generate a unique name for a target.
        name: The base name that the Xcode target should use. Multiple
            `_xcode_target`s can have the same name; the generator will
            disambiguate them.
        label: The `Label` of the `Target`.
        configuration: The configuration of the `Target`.
        package_bin_dir: The package directory for the `Target` within
            `ctx.bin_dir`.
        platform: The value returned from `process_platform`.
        product: The value returned from `process_product`.
        is_bundle: Whether the target is a bundle.
        is_swift: Whether the target compiles Swift code.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        avoid_infos: A list of `XcodeProjInfo`s for the targets that have
            already consumed resources, or linked to libraries.
        build_settings: A `dict` of Xcode build settings for the target.
        search_paths: The value returned from `_process_search_paths`.
        modulemaps: The value returned from `_process_modulemaps`.
        swiftmodules: The value returned from `_process_swiftmodules`.
        resource_bundles: The value returned from
            `resource_bundle_products.collect`.
        inputs: The value returned from `input_files.collect`.
        linker_inputs: A value returned from `linker_input_files.collect`.
        info_plist: A value as returned by `files.file_path` or `None`.
        entitlements: A value as returned by `files.file_path()` or `None`.
        dependencies: A `depset` of `id`s of targets that this target depends
            on.
        outputs: A value returned from `output_files.collect`.

    Returns:
        An element of a json array string. This should be wrapped with `"[{}]"`
        to create a json array string, possibly joining multiples of these
        strings with `","`.
    """
    target = json.encode(struct(
        name = name,
        label = str(label),
        configuration = configuration,
        package_bin_dir = package_bin_dir,
        platform = platform,
        product = product_to_dto(product),
        is_swift = is_swift,
        test_host = test_host,
        build_settings = build_settings,
        search_paths = search_paths,
        modulemaps = [file_path_to_dto(fp) for fp in modulemaps.file_paths],
        swiftmodules = [file_path_to_dto(fp) for fp in swiftmodules],
        resource_bundles = resource_bundle_products.to_dto(
            resource_bundles,
            avoid_infos = avoid_infos,
        ),
        inputs = input_files.to_dto(
            inputs,
            is_bundle = is_bundle,
            avoid_infos = avoid_infos,
        ),
        linker_inputs = linker_input_files.to_dto(linker_inputs),
        info_plist = file_path_to_dto(info_plist),
        entitlements = file_path_to_dto(entitlements),
        dependencies = dependencies.to_list(),
        outputs = output_files.to_dto(outputs),
    ))

    # Since we use a custom dictionary key type in
    # `//tools/generator/src:DTO.swift`, we need to use alternating keys and
    # values to get the correct dictionary representation.
    return '"{id}",{target}'.format(id = id, target = target)
