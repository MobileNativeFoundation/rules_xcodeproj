"""Functions for processing library targets."""

load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":build_settings.bzl", "get_product_module_name")
load(":collections.bzl", "set_if_true")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":configuration.bzl", "get_configuration")
load(":files.bzl", "build_setting_path", "join_paths_ignoring_empty")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":lldb_contexts.bzl", "lldb_contexts")
load(":opts.bzl", "process_opts")
load(":output_files.bzl", "output_files")
load(":platform.bzl", "platform_info")
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
        automatic_target_info,
        transitive_infos):
    """Gathers information about a library target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to process.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    configuration = get_configuration(ctx)
    label = target.label
    id = get_id(label = label, configuration = configuration)

    build_settings = {}

    product_name = ctx.rule.attr.name
    set_if_true(
        build_settings,
        "PRODUCT_MODULE_NAME",
        get_product_module_name(ctx = ctx, target = target),
    )
    dependencies, transitive_dependencies = process_dependencies(
        automatic_target_info = automatic_target_info,
        transitive_infos = transitive_infos,
    )

    deps_infos = [
        dep[XcodeProjInfo]
        for attr in automatic_target_info.implementation_deps
        for dep in getattr(ctx.rule.attr, attr, [])
        if XcodeProjInfo in dep
    ]

    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None

    compilation_providers = comp_providers.collect(
        cc_info = target[CcInfo],
        objc = objc,
        swift_info = swift_info,
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
    build_settings["ENABLE_BITCODE"] = str(cpp.apple_bitcode_mode) != "none"

    set_if_true(
        build_settings,
        "CLANG_ENABLE_MODULES",
        getattr(ctx.rule.attr, "enable_modules", False),
    )

    platform = platform_info.collect(ctx = ctx)
    product = process_product(
        ctx = ctx,
        target = target,
        product_name = product_name,
        product_type = "com.apple.product-type.library.static",
        linker_inputs = linker_inputs,
    )

    modulemaps = process_modulemaps(swift_info = swift_info)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
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
    outputs = output_files.collect(
        ctx = ctx,
        debug_outputs = debug_outputs,
        id = id,
        inputs = inputs,
        output_group_info = output_group_info,
        swift_info = swift_info,
        transitive_infos = transitive_infos,
    )

    if inputs.pch:
        build_settings["GCC_PREFIX_HEADER"] = build_setting_path(
            file = inputs.pch,
        )

    package_bin_dir = join_paths_ignoring_empty(
        ctx.bin_dir.path,
        label.workspace_root,
        label.package,
    )
    search_paths, conlyopts, cxxopts, swiftcopts, clang_opts = process_opts(
        ctx = ctx,
        build_mode = build_mode,
        has_c_sources = inputs.has_c_sources,
        has_cxx_sources = inputs.has_cxx_sources,
        target = target,
        implementation_compilation_context = (
            compilation_providers.implementation_compilation_context
        ),
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    swiftmodules = process_swiftmodules(swift_info = swift_info)
    lldb_context = lldb_contexts.collect(
        id = id,
        is_swift = is_swift,
        clang_opts = clang_opts,
        search_paths = search_paths,
        swiftmodules = swiftmodules,
        transitive_infos = [
            info
            for attr, info in transitive_infos
            if (info.target_type in
                automatic_target_info.xcode_targets.get(attr, [None]))
        ],
    )

    xcode_target = xcode_targets.make(
        id = id,
        label = label,
        configuration = configuration,
        package_bin_dir = package_bin_dir,
        platform = platform,
        product = product,
        is_swift = is_swift,
        build_settings = build_settings,
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        swiftcopts = swiftcopts,
        search_paths = search_paths,
        modulemaps = modulemaps,
        swiftmodules = swiftmodules,
        inputs = inputs,
        linker_inputs = linker_inputs,
        dependencies = dependencies,
        transitive_dependencies = transitive_dependencies,
        outputs = outputs,
        should_create_xcode_target = target.files != depset(),
    )

    mergable_xcode_library_targets = [
        struct(
            id = xcode_target.id,
            product_path = xcode_target.product.file_path,
        ),
    ]

    return processed_target(
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        inputs = inputs,
        library = product.file,
        lldb_context = lldb_context,
        mergable_xcode_library_targets = mergable_xcode_library_targets,
        outputs = outputs,
        search_paths = search_paths,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_target,
    )
