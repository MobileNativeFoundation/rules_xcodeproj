"""Functions for processing library targets."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load("//xcodeproj/internal:build_settings.bzl", "get_product_module_name")
load("//xcodeproj/internal:configuration.bzl", "calculate_configuration")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_TUPLE",
)
load("//xcodeproj/internal:target_id.bzl", "get_id")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(
    ":files.bzl",
    "join_paths_ignoring_empty",
)
load(":input_files.bzl", "input_files", bwx_ogroups = "bwx_output_groups")
load(":linker_input_files.bzl", "linker_input_files")
load(":opts.bzl", "opts")
load(":output_files.bzl", "output_files", bwb_ogroups = "bwb_output_groups")
load(":pbxproj_partials.bzl", "pbxproj_partials")
load("//xcodeproj/internal:platforms.bzl", "platforms")
load(":processed_target.bzl", "processed_target")
load(":product.bzl", "process_product")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "process_modulemaps",
)
load(":xcode_targets.bzl", "xcode_targets")

def process_library_target(
        *,
        ctx,
        build_mode,
        target,
        attrs,
        automatic_target_info,
        generate_target,
        transitive_infos):
    """Gathers information about a library target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        generate_target: Whether an Xcode target should be generated for this
            target.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    configuration = calculate_configuration(bin_dir_path = ctx.bin_dir.path)
    label = automatic_target_info.label
    id = get_id(label = label, configuration = configuration)

    product_name = ctx.rule.attr.name

    dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
        transitive_infos = transitive_infos,
    )

    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    compilation_providers = comp_providers.collect(
        cc_info = target[CcInfo],
        objc = objc,
    )
    linker_inputs = linker_input_files.collect(
        target = target,
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
    )

    platform = platforms.collect(ctx = ctx)
    module_name_attribute, module_name = get_product_module_name(
        ctx = ctx,
        target = target,
    )

    # Value taken from `PRODUCT_TYPE_ENCODED` in `product.bzl`, for
    # `com.apple.product-type.library.static`
    product_type = "L"

    product = process_product(
        ctx = ctx,
        label = label,
        target = target,
        product_name = product_name,
        product_type = product_type,
        module_name = module_name,
        module_name_attribute = module_name_attribute,
        linker_inputs = linker_inputs,
    )

    (target_inputs, provider_inputs) = input_files.collect(
        ctx = ctx,
        build_mode = build_mode,
        target = target,
        attrs = attrs,
        id = id,
        platform = platform,
        product = product,
        linker_inputs = linker_inputs,
        automatic_target_info = automatic_target_info,
        transitive_infos = transitive_infos,
    )

    debug_outputs = target[apple_common.AppleDebugOutputs] if apple_common.AppleDebugOutputs in target else None
    output_group_info = (
        target[OutputGroupInfo] if OutputGroupInfo in target else None
    )
    (
        target_outputs,
        provider_outputs,
        bwb_output_groups_metadata,
    ) = output_files.collect(
        actions = ctx.actions,
        debug_outputs = debug_outputs,
        id = id,
        name = label.name,
        output_group_info = output_group_info,
        product = product,
        swift_info = swift_info,
        transitive_infos = transitive_infos,
    )

    package_bin_dir = join_paths_ignoring_empty(
        ctx.bin_dir.path,
        label.workspace_root,
        label.package,
    )

    params = opts.collect_params(
        c_sources = target_inputs.c_sources,
        cxx_sources = target_inputs.cxx_sources,
        target = target,
    )

    # Check for `target.files != depset()` is to exclude source-less library
    # targets (e.g. header or define only `objc_library` targets)
    is_focused = generate_target and target.files != depset()

    (
        target_build_settings,
        swift_debug_settings_file,
        params_files,
    ) = pbxproj_partials.write_target_build_settings(
        actions = ctx.actions,
        apple_generate_dsym = ctx.fragments.cpp.apple_generate_dsym,
        colorize = ctx.attr._colorize[BuildSettingInfo].value,
        conly_args = params.conly_args,
        cxx_args = params.cxx_args,
        generate_build_settings = is_focused,
        name = label.name,
        swift_args = params.swift_args,
        swift_debug_settings_to_merge = EMPTY_DEPSET,
        tool = ctx.executable._target_build_settings_generator,
    )

    swift_debug_settings = depset(
        [swift_debug_settings_file] if swift_debug_settings_file else None,
        transitive = [
            info.swift_debug_settings
            for info in transitive_infos
        ],
        order = "topological",
    )

    bwx_output_groups = bwx_ogroups.collect(
        build_mode = build_mode,
        id = id,
        target_inputs = target_inputs,
        modulemaps = process_modulemaps(swift_info = swift_info),
        params_files = params_files,
        transitive_infos = transitive_infos,
    )

    bwb_output_groups = bwb_ogroups.collect(
        bwx_output_groups = bwx_output_groups,
        metadata = bwb_output_groups_metadata,
        transitive_infos = transitive_infos,
    )

    xcode_target_inputs = xcode_targets.make_inputs(
        inputs = target_inputs,
    )

    swift_outputs = target_outputs.direct_outputs.swift

    if str(label) in ctx.attr._unfocused_labels:
        mergeable_infos = depset(
            [
                # We still set a value to prevent unfocused targets from
                # changing which targets _could_ merge. This is filtered out
                # in `top_level_targets.bzl`.
                struct(
                    id = None,
                    swiftmodule = bool(swift_outputs),
                ),
            ],
        )
    else:
        if swift_outputs and swift_outputs.indexstore:
            indexstores = (swift_outputs.indexstore,)
        else:
            indexstores = EMPTY_TUPLE
        mergeable_infos = depset(
            [
                struct(
                    id = id,
                    indexstores = indexstores,
                    inputs = xcode_target_inputs,
                    module_name = module_name,
                    package_bin_dir = package_bin_dir,
                    params = params,
                    product_file = product.file,
                    swift_debug_settings = swift_debug_settings,
                    swiftmodule = (
                        swift_outputs.module.swiftmodule if swift_outputs else None
                    ),
                ),
            ],
        )

    if is_focused:
        xcode_target = xcode_targets.make(
            build_settings_file = target_build_settings,
            configuration = configuration,
            dependencies = dependencies,
            has_c_params = bool(params.conly_args),
            has_cxx_params = bool(params.cxx_args),
            id = id,
            library_inputs = xcode_target_inputs,
            label = label,
            outputs = target_outputs,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = product,
            transitive_dependencies = transitive_dependencies,
        )
    else:
        xcode_target = None

    return processed_target(
        bwb_output_groups = bwb_output_groups,
        bwx_output_groups = bwx_output_groups,
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        inputs = provider_inputs,
        mergeable_infos = mergeable_infos,
        outputs = provider_outputs,
        platform = platform.apple_platform,
        swift_debug_settings = swift_debug_settings,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_target,
    )
