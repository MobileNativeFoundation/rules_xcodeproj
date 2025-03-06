"""Functions for processing library targets."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@build_bazel_rules_apple//apple:providers.bzl", "AppleDebugOutputsInfo")
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo", "SwiftProtoInfo")
load("//xcodeproj/internal:build_settings.bzl", "get_product_module_name")
load("//xcodeproj/internal:compilation_providers.bzl", "compilation_providers")
load("//xcodeproj/internal:compiler_args.bzl", "compiler_args")
load("//xcodeproj/internal:configuration.bzl", "calculate_configuration")
load("//xcodeproj/internal:dependencies.bzl", "dependencies")
load(
    "//xcodeproj/internal:incremental_xcode_targets.bzl",
    xcode_targets = "incremental_xcode_targets",
)
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_TUPLE",
)
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")
load("//xcodeproj/internal:platforms.bzl", "platforms")
load("//xcodeproj/internal:products.bzl", "products")
load("//xcodeproj/internal:target_id.bzl", "get_id")
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

def _process_incremental_library_target(
        *,
        ctx,
        target,
        attrs,
        automatic_target_info,
        generate_target,
        rule_attr,
        transitive_infos):
    """Gathers information about a library target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        generate_target: Whether an Xcode target should be generated for this
            target.
        rule_attr: `ctx.rule.attr`.
        transitive_infos: A `list` of `XcodeProjInfo`s from the transitive
            dependencies of `target`.

    Returns:
        A value from `processed_target`.
    """
    bin_dir_path = ctx.bin_dir.path
    configuration = calculate_configuration(bin_dir_path = bin_dir_path)
    label = automatic_target_info.label
    id = get_id(label = label, configuration = configuration)

    product_name = rule_attr.name

    direct_dependencies, transitive_dependencies = dependencies.collect(
        transitive_infos = transitive_infos,
    )

    cc_info = target[CcInfo]
    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    (
        target_compilation_providers,
        provider_compilation_providers,
    ) = compilation_providers.collect(
        cc_info = cc_info,
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

    (target_inputs, provider_inputs) = input_files.collect(
        ctx = ctx,
        attrs = attrs,
        automatic_target_info = automatic_target_info,
        label = label,
        linker_inputs = linker_inputs,
        platform = platform,
        rule_attr = rule_attr,
        swift_proto_info = (
            target[SwiftProtoInfo] if SwiftProtoInfo in target else None
        ),
        transitive_infos = transitive_infos,
    )

    package_bin_dir = products.calculate_packge_bin_dir(
        bin_dir_path = bin_dir_path,
        label = label,
    )

    args = compiler_args.collect(
        c_sources = target_inputs.c_sources,
        cxx_sources = target_inputs.cxx_sources,
        target = target,
    )

    (
        target_build_settings,
        swift_debug_settings_file,
        params_files,
    ) = pbxproj_partials.write_target_build_settings(
        actions = actions,
        apple_generate_dsym = ctx.fragments.cpp.apple_generate_dsym,
        colorize = ctx.attr._colorize[BuildSettingInfo].value,
        conly_args = args.conly,
        cxx_args = args.cxx,
        generate_build_settings = generate_target,
        generate_swift_debug_settings = bool(args.swift),
        name = label.name,
        swift_args = args.swift,
        tool = ctx.executable._target_build_settings_generator,
    )

    swift_debug_settings = depset(
        [swift_debug_settings_file] if swift_debug_settings_file else None,
        transitive = [
            info.swift_debug_settings
            for info in transitive_infos
        ] if not swift_debug_settings_file else None,
    )

    if AppleDebugOutputsInfo in target:
        debug_outputs = target[AppleDebugOutputsInfo]
    else:
        debug_outputs = None

    (
        target_outputs,
        provider_outputs,
        target_output_groups_metadata,
    ) = output_files.collect(
        actions = actions,
        compile_params_files = params_files,
        debug_outputs = debug_outputs,
        id = id,
        name = label.name,
        output_group_info = (
            target[OutputGroupInfo] if OutputGroupInfo in target else None
        ),
        product = product,
        swift_info = swift_info,
        transitive_infos = transitive_infos,
    )
    target_output_groups = output_groups.collect(
        metadata = target_output_groups_metadata,
        transitive_infos = transitive_infos,
    )

    swift_outputs = target_outputs.direct_outputs.swift

    if generate_target:
        module_name_attribute, module_name = get_product_module_name(
            rule_attr = rule_attr,
            target = target,
        )

        if swift_outputs and swift_outputs.indexstore:
            indexstores = (swift_outputs.indexstore,)
        else:
            indexstores = EMPTY_TUPLE

        mergeable_infos = depset(
            [
                struct(
                    args = args,
                    id = id,
                    indexstores = indexstores,
                    inputs = target_inputs.xcode_inputs,
                    module_name = module_name,
                    package_bin_dir = package_bin_dir,
                    premerged_info = None,
                    product_file = product.file,
                    swift_debug_settings = swift_debug_settings,
                    swiftmodule = (
                        swift_outputs.module.swiftmodule if swift_outputs else None
                    ),
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
            inputs = target_inputs.xcode_inputs,
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
                    premerged_info = None,
                    swiftmodule = bool(swift_outputs),
                ),
            ],
        )
        xcode_target = None

    return processed_targets.make(
        compilation_providers = provider_compilation_providers,
        direct_dependencies = direct_dependencies,
        inputs = provider_inputs,
        mergeable_infos = mergeable_infos,
        outputs = provider_outputs,
        platform = platform.apple_platform,
        swift_debug_settings = swift_debug_settings,
        target_output_groups = target_output_groups,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_target,
    )

incremental_library_targets = struct(
    process = _process_incremental_library_target,
)
