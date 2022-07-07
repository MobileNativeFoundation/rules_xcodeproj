"""Functions for creating data structures related to processed bazel targets."""

load(":files.bzl", "file_path_to_dto")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":output_files.bzl", "output_files")
load(":platform.bzl", "platform_info")
load(":product.bzl", "product_to_dto")
load(":providers.bzl", "target_type")

def processed_target(
        *,
        automatic_target_info,
        dependencies,
        inputs,
        linker_inputs,
        non_mergable_targets = None,
        outputs,
        potential_target_merges = None,
        resource_bundle_informations = None,
        search_paths,
        target,
        xcode_target):
    """Generates the return value for target processing functions.

    Args:
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            the target.
        dependencies: A `list` of target ids of direct dependencies of this
            target.
        inputs: A value as returned from `input_files.collect` that will
            provide values for the `XcodeProjInfo.inputs` field.
        linker_inputs: A value returned from `linker_input_files.collect`
            that will provide values for the `XcodeProjInfo.linker_inputs`
            field.
        non_mergable_targets: An optional `list` of strings that will be in the
            `XcodeProjInfo.non_mergable_targets` `depset`.
        outputs: A value as returned from `output_files.collect` that will
            provide values for the `XcodeProjInfo.outputs` field.
        potential_target_merges: An optional `list` of `struct`s that will be in
            the `XcodeProjInfo.potential_target_merges` `depset`.
        resource_bundle_informations: An optional `list` of `struct`s that will
            be in the `XcodeProjInfo.resource_bundle_informations` `depset`.
        search_paths: The value returned from `_process_search_paths`.
        target: An optional `XcodeProjInfo.target` `struct`.
        xcode_target: An optional string that will be in the
            `XcodeProjInfo.xcode_targets` `depset`.

    Returns:
        A `struct` containing fields for each argument.
    """
    return struct(
        automatic_target_info = automatic_target_info,
        dependencies = dependencies,
        inputs = inputs,
        linker_inputs = linker_inputs,
        non_mergable_targets = non_mergable_targets,
        outputs = outputs,
        potential_target_merges = potential_target_merges,
        resource_bundle_informations = resource_bundle_informations,
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
        is_swift,
        test_host = None,
        build_settings,
        search_paths,
        modulemaps,
        swiftmodules,
        inputs,
        linker_inputs,
        info_plist,
        watch_application = None,
        extensions = [],
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
        is_swift: Whether the target compiles Swift code.
        test_host: The `id` of the target that is the test host for this
            target, or `None` if this target does not have a test host.
        build_settings: A `dict` of Xcode build settings for the target.
        search_paths: The value returned from `_process_search_paths`.
        modulemaps: The value returned from `_process_modulemaps`.
        swiftmodules: The value returned from `_process_swiftmodules`.
        inputs: The value returned from `input_files.collect`.
        linker_inputs: A value returned from `linker_input_files.collect`.
        info_plist: A value as returned by `files.file_path` or `None`.
        watch_application: The `id` of the watch application target that should
            be embedded in this target, or `None`.
        extensions: A `list` of `id`s of application extension targets that
            should be embedded in this target.
        dependencies: A `depset` of `id`s of targets that this target depends
            on.
        outputs: A value returned from `output_files.collect`.

    Returns:
        An element of a json array string. This should be wrapped with `"[{}]"`
        to create a json array string, possibly joining multiples of these
        strings with `","`.
    """
    platform_dto = platform_info.to_dto(
        platform,
        build_settings = build_settings,
    )

    target = json.encode(struct(
        name = name,
        label = str(label),
        configuration = configuration,
        package_bin_dir = package_bin_dir,
        platform = platform_dto,
        product = product_to_dto(product),
        is_swift = is_swift,
        test_host = test_host,
        build_settings = build_settings,
        search_paths = search_paths,
        modulemaps = [file_path_to_dto(fp) for fp in modulemaps.file_paths],
        swiftmodules = [file_path_to_dto(fp) for fp in swiftmodules],
        resource_bundle_dependencies = (
            inputs.resource_bundle_dependencies.to_list()
        ),
        inputs = input_files.to_dto(inputs),
        linker_inputs = linker_input_files.to_dto(linker_inputs),
        info_plist = file_path_to_dto(info_plist),
        watch_application = watch_application,
        extensions = extensions,
        dependencies = dependencies.to_list(),
        outputs = output_files.to_dto(outputs),
    ))

    # Since we use a custom dictionary key type in
    # `//tools/generator/src:DTO.swift`, we need to use alternating keys and
    # values to get the correct dictionary representation.
    return '"{id}",{target}'.format(id = id, target = target)
