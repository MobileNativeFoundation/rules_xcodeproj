"""Functions for processing library targets."""

load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":build_settings.bzl", "get_product_module_name")
load(":collections.bzl", "set_if_true")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":configuration.bzl", "calculate_configuration")
load(":files.bzl", "build_setting_path", "join_paths_ignoring_empty")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":lldb_contexts.bzl", "lldb_contexts")
load(":opts.bzl", "process_opts")
load(":output_files.bzl", "output_files")
load(":platforms.bzl", "platforms")
load(":processed_target.bzl", "processed_target")
load(":product.bzl", "process_product")
load(":providers.bzl", "XcodeProjInfo")
load(":target_id.bzl", "get_id")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "process_modulemaps",
    "process_swiftmodules",
)
load(":xcode_targets.bzl", "xcode_targets")

def process_library_target(
        *,
        ctx,
        build_mode,
        target,
        attrs,
        automatic_target_info,
        transitive_infos):
    """Gathers information about a library target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    configuration = calculate_configuration(bin_dir_path = ctx.bin_dir.path)
    label = target.label
    id = get_id(label = label, configuration = configuration)

    build_settings = {}

    product_name = ctx.rule.attr.name
    module_name_attribute, product_module_name = get_product_module_name(
        ctx = ctx,
        target = target,
    )
    set_if_true(
        build_settings,
        "PRODUCT_MODULE_NAME",
        product_module_name,
    )

    dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
        transitive_infos = transitive_infos,
    )

    deps_infos = [
        dep[XcodeProjInfo]
        for attr in automatic_target_info.implementation_deps
        for dep in getattr(ctx.rule.attr, attr, [])
        if XcodeProjInfo in dep
    ]

    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    (
        compilation_providers,
        implementation_compilation_context,
    ) = comp_providers.collect(
        cc_info = target[CcInfo],
        objc = objc,
        is_xcode_target = True,
        transitive_implementation_providers = [
            info.compilation_providers
            for info in deps_infos
        ],
    )
    linker_inputs = linker_input_files.collect(
        target = target,
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
    )

    cpp = ctx.fragments.cpp

    # TODO: Get the value for device builds, even when active config is not for
    # device, as Xcode only uses this value for device builds
    if str(cpp.apple_bitcode_mode) != "none":
        build_settings["ENABLE_BITCODE"] = True

    set_if_true(
        build_settings,
        "CLANG_ENABLE_MODULES",
        getattr(ctx.rule.attr, "enable_modules", False),
    )

    platform = platforms.collect(ctx = ctx)
    product = process_product(
        ctx = ctx,
        target = target,
        product_name = product_name,
        product_type = "com.apple.product-type.library.static",
        module_name_attribute = module_name_attribute,
        linker_inputs = linker_inputs,
    )

    modulemaps = process_modulemaps(swift_info = swift_info)
    (target_inputs, provider_inputs) = input_files.collect(
        ctx = ctx,
        target = target,
        attrs = attrs,
        id = id,
        platform = platform,
        is_bundle = False,
        product = product,
        linker_inputs = linker_inputs,
        automatic_target_info = automatic_target_info,
        modulemaps = modulemaps,
        transitive_infos = transitive_infos,
    )
    debug_outputs = target[apple_common.AppleDebugOutputs] if apple_common.AppleDebugOutputs in target else None
    output_group_info = target[OutputGroupInfo] if OutputGroupInfo in target else None
    (target_outputs, provider_outputs) = output_files.collect(
        ctx = ctx,
        debug_outputs = debug_outputs,
        id = id,
        inputs = target_inputs,
        output_group_info = output_group_info,
        swift_info = swift_info,
        transitive_infos = transitive_infos,
    )

    if target_inputs.pch:
        build_settings["GCC_PREFIX_HEADER"] = build_setting_path(
            file = target_inputs.pch,
        )

    package_bin_dir = join_paths_ignoring_empty(
        ctx.bin_dir.path,
        label.workspace_root,
        label.package,
    )
    (
        c_params,
        cxx_params,
        swift_params,
        swift_sub_params,
        c_has_fortify_source,
        cxx_has_fortify_source,
    ) = process_opts(
        ctx = ctx,
        build_mode = build_mode,
        c_sources = target_inputs.c_sources,
        cxx_sources = target_inputs.cxx_sources,
        target = target,
        implementation_compilation_context = implementation_compilation_context,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    swiftmodules = process_swiftmodules(swift_info = swift_info)
    lldb_context = lldb_contexts.collect(
        build_mode = build_mode,
        id = id,
        is_swift = bool(swift_params),
        swift_sub_params = swift_sub_params,
        swiftmodules = swiftmodules,
        transitive_infos = transitive_infos,
    )

    xcode_target = xcode_targets.make(
        id = id,
        label = label,
        configuration = configuration,
        package_bin_dir = package_bin_dir,
        platform = platform,
        product = product,
        build_settings = build_settings,
        c_params = c_params,
        cxx_params = cxx_params,
        swift_params = swift_params,
        c_has_fortify_source = c_has_fortify_source,
        cxx_has_fortify_source = cxx_has_fortify_source,
        modulemaps = modulemaps,
        swiftmodules = swiftmodules,
        inputs = target_inputs,
        linker_inputs = linker_inputs,
        dependencies = dependencies,
        transitive_dependencies = transitive_dependencies,
        outputs = target_outputs,
        should_create_xcode_target = target.files != depset(),
    )

    mergable_xcode_library_targets = [
        struct(
            id = xcode_target.id,
            product_path = xcode_target.product.file_path,
        ),
    ]

    return processed_target(
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        inputs = provider_inputs,
        library = product.file,
        lldb_context = lldb_context,
        mergable_xcode_library_targets = mergable_xcode_library_targets,
        outputs = provider_outputs,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_target,
    )
