"""Functions for processing mixed-language library targets."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("//xcodeproj/internal:build_settings.bzl", "get_product_module_name")
load("//xcodeproj/internal:compilation_providers.bzl", "compilation_providers")
load("//xcodeproj/internal:configuration.bzl", "calculate_configuration")
load("//xcodeproj/internal:dependencies.bzl", "dependencies")
load(
    "//xcodeproj/internal:incremental_xcode_targets.bzl",
    xcode_targets = "incremental_xcode_targets",
)
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")
load("//xcodeproj/internal:platforms.bzl", "platforms")
load("//xcodeproj/internal:products.bzl", "products")
load("//xcodeproj/internal:target_id.bzl", "get_id")
load("//xcodeproj/internal:xcodeprojinfo.bzl", "XcodeProjInfo")
load(
    "//xcodeproj/internal/files:incremental_input_files.bzl",
    input_files = "incremental_input_files",
)
load(
    "//xcodeproj/internal/files:incremental_output_files.bzl",
    "output_groups",
    output_files = "incremental_output_files",
)
load("//xcodeproj/internal/files:linker_input_files.bzl", "linker_input_files")
load(
    ":incremental_processed_targets.bzl",
    processed_targets = "incremental_processed_targets",
)
load(":mergeable_infos.bzl", mergeable_infos_module = "mergeable_infos")

def _process_mixed_language_library_target(
        *,
        ctx,
        target,
        automatic_target_info,
        generate_target,
        rule_attr,
        transitive_infos):
    """Gathers information about a library target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        generate_target: Whether an Xcode target should be generated for this
            target.
        rule_attr: `ctx.rule.attr`.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        A `tuple` of three values:

        *   A value from `processed_target`.
        *   The `Label` of the Swift target.
        *   The `Label` of the Clang target.
    """
    bin_dir_path = ctx.bin_dir.path
    configuration = calculate_configuration(bin_dir_path = bin_dir_path)
    label = automatic_target_info.label
    id = get_id(label = label, configuration = configuration)

    clang_target_info = rule_attr.clang_target[XcodeProjInfo]
    swift_target_info = rule_attr.swift_target[XcodeProjInfo]
    mixed_target_infos = [swift_target_info, clang_target_info]

    product_name = rule_attr.name

    direct_dependencies, transitive_dependencies = dependencies.collect(
        transitive_infos = transitive_infos,
    )

    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    (
        target_compilation_providers,
        provider_compilation_providers,
    ) = compilation_providers.collect(
        cc_info = target[CcInfo],
        objc = objc,
    )
    linker_inputs = linker_input_files.collect(
        automatic_target_info = automatic_target_info,
        compilation_providers = target_compilation_providers,
        target = target,
    )

    platform = platforms.collect(ctx = ctx)

    actions = ctx.actions

    # Value taken from `PRODUCT_TYPE_ENCODED` in `product.bzl`, for
    # `com.apple.product-type.library.static`
    product_type = "L"

    product = products.collect(
        actions = actions,
        linker_inputs = linker_inputs,
        product_name = product_name,
        product_type = product_type,
        target = target,
    )

    mergeable_info_and_ids = mergeable_infos_module.calculate_mixed_language(
        clang_target_info = clang_target_info,
        product_type = product_type,
        swift_target_info = swift_target_info,
    )
    if mergeable_info_and_ids:
        merged_target_ids = [(id, mergeable_info_and_ids.ids)]
        mergeable_info = mergeable_info_and_ids.merged
    else:
        merged_target_ids = None
        mergeable_info = None

    (xcode_inputs, provider_inputs) = input_files.collect_mixed_language(
        mergeable_info = mergeable_info,
        mixed_target_infos = mixed_target_infos,
    )

    actual_package_bin_dir = products.calculate_packge_bin_dir(
        bin_dir_path = bin_dir_path,
        label = label,
    )

    if mergeable_info:
        package_bin_dir = mergeable_info.package_bin_dir
        args = struct(
            conly = mergeable_info.conly_args,
            cxx = mergeable_info.cxx_args,
            swift = mergeable_info.swift_args,
        )

        indexstore_override_path = actual_package_bin_dir + "/" + label.name
        indexstore_overrides = [
            (indexstore, indexstore_override_path)
            for indexstore in mergeable_info.indexstores
        ]
    else:
        package_bin_dir = actual_package_bin_dir
        args = struct(
            conly = [],
            cxx = [],
            swift = [],
        )
        indexstore_overrides = []

    (
        target_build_settings,
        _,
        params_files,
    ) = pbxproj_partials.write_target_build_settings(
        actions = actions,
        apple_generate_dsym = ctx.fragments.cpp.apple_generate_dsym,
        colorize = ctx.attr._colorize[BuildSettingInfo].value,
        conly_args = args.conly,
        cxx_args = args.cxx,
        generate_build_settings = generate_target,
        generate_swift_debug_settings = False,
        include_self_swift_debug_settings = False,
        name = label.name,
        swift_args = args.swift,
        tool = ctx.executable._target_build_settings_generator,
    )

    (
        target_outputs,
        provider_outputs,
        target_output_groups_metadata,
    ) = output_files.collect_mixed_language(
        actions = actions,
        compile_params_files = params_files,
        id = id,
        indexstore_overrides = indexstore_overrides,
        name = label.name,
        mixed_target_infos = mixed_target_infos,
    )
    target_output_groups = output_groups.collect(
        metadata = target_output_groups_metadata,
        transitive_infos = mixed_target_infos,
    )

    if generate_target and mergeable_info_and_ids:
        module_name_attribute, module_name = get_product_module_name(
            rule_attr = rule_attr,
            target = target,
        )

        mergeable_infos = depset(
            [
                struct(
                    id = id,
                    premerged_info = mergeable_info,
                ),
            ],
        )

        xcode_target = xcode_targets.make(
            build_settings_file = target_build_settings,
            configuration = configuration,
            direct_dependencies = direct_dependencies,
            has_c_params = bool(args.conly),
            has_cxx_params = bool(args.cxx),
            id = id,
            inputs = xcode_inputs,
            is_top_level = False,
            label = label,
            module_name = module_name,
            module_name_attribute = module_name_attribute,
            outputs = target_outputs,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = product.xcode_product,
            transitive_dependencies = transitive_dependencies,
            linker_inputs_for_libs_search_paths = linker_input_files
                .get_linker_inputs_for_libs_search_paths(linker_inputs),
            libraries_path_to_link = linker_input_files
                .get_libraries_path_to_link(linker_inputs),
        )
    else:
        mergeable_infos = depset(
            [
                # We still set a value to prevent unfocused targets from
                # changing which targets _could_ merge. This is filtered out
                # in `top_level_targets.bzl`.
                struct(
                    id = None,
                    # `premerged_info` is only checked for truthiness if
                    # `id == None`. No other values are checked in this case.
                    premerged_info = True,
                ),
            ],
        )
        xcode_target = None

    processed_target = processed_targets.make(
        compilation_providers = provider_compilation_providers,
        direct_dependencies = direct_dependencies,
        inputs = provider_inputs,
        mergeable_infos = mergeable_infos,
        merged_target_ids = merged_target_ids,
        outputs = provider_outputs,
        platform = platform.apple_platform,
        swift_debug_settings = swift_target_info.swift_debug_settings,
        target_output_groups = target_output_groups,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_target,
    )

    return (
        processed_target,
        swift_target_info.label,
        clang_target_info.label,
    )

mixed_language_library_targets = struct(
    process = _process_mixed_language_library_target,
)
