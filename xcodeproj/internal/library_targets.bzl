"""Functions for processing library targets."""

load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":build_settings.bzl", "get_product_module_name")
load(":collections.bzl", "set_if_true")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":configuration.bzl", "get_configuration")
load(":files.bzl", "join_paths_ignoring_empty")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":opts.bzl", "process_opts")
load(":output_files.bzl", "output_files")
load(":platform.bzl", "platform_info")
load(":processed_target.bzl", "processed_target", "xcode_target")
load(":product.bzl", "process_product")
load(":search_paths.bzl", "process_search_paths")
load(":target_id.bzl", "get_id")
load(
    ":target_properties.bzl",
    "process_defines",
    "process_dependencies",
    "process_modulemaps",
    "process_swiftmodules",
    "should_bundle_resources",
    "should_include_outputs",
    "should_include_outputs_output_groups",
)

def process_library_target(
        *,
        ctx,
        target,
        automatic_target_info,
        transitive_infos):
    """Gathers information about a library target.

    Args:
        ctx: The aspect context.
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

    package_bin_dir = join_paths_ignoring_empty(
        ctx.bin_dir.path,
        label.workspace_root,
        label.package,
    )
    opts_search_paths = process_opts(
        ctx = ctx,
        target = target,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )
    product_name = ctx.rule.attr.name
    set_if_true(
        build_settings,
        "PRODUCT_MODULE_NAME",
        get_product_module_name(ctx = ctx, target = target),
    )
    dependencies = process_dependencies(
        automatic_target_info = automatic_target_info,
        transitive_infos = transitive_infos,
    )

    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None

    compilation_providers = comp_providers.collect(
        cc_info = target[CcInfo],
        objc = objc,
        swift_info = swift_info,
        is_xcode_target = True,
    )
    linker_inputs = linker_input_files.collect(
        ctx = ctx,
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

    set_if_true(
        build_settings,
        "ENABLE_TESTING_SEARCH_PATHS",
        getattr(ctx.rule.attr, "testonly", False),
    )

    platform = platform_info.collect(
        ctx = ctx,
        minimum_deployment_os_version = None,
    )
    product = process_product(
        target = target,
        product_name = product_name,
        product_type = "com.apple.product-type.library.static",
        bundle_file_path = None,
        linker_inputs = linker_inputs,
    )

    bundle_resources = should_bundle_resources(ctx = ctx)

    modulemaps = process_modulemaps(swift_info = swift_info)
    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        platform = platform,
        bundle_resources = bundle_resources,
        is_bundle = False,
        linker_inputs = linker_inputs,
        automatic_target_info = automatic_target_info,
        additional_files = modulemaps.files,
        transitive_infos = transitive_infos,
        avoid_deps = [],
    )
    outputs = output_files.collect(
        target_files = [],
        bundle_info = None,
        default_info = target[DefaultInfo],
        swift_info = swift_info,
        id = id,
        transitive_infos = transitive_infos,
        should_produce_dto = should_include_outputs(ctx = ctx),
        should_produce_output_groups = should_include_outputs_output_groups(
            ctx = ctx,
        ),
    )

    process_defines(
        compilation_providers = compilation_providers,
        build_settings = build_settings,
    )
    search_paths = process_search_paths(
        compilation_providers = compilation_providers,
        bin_dir_path = ctx.bin_dir.path,
        opts_search_paths = opts_search_paths,
    )

    return processed_target(
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        inputs = inputs,
        library = linker_input_files.get_primary_static_library(linker_inputs),
        outputs = outputs,
        search_paths = search_paths,
        target = struct(
            id = id,
            label = label,
            is_bundle = False,
            product_path = product.path,
        ),
        xcode_target = xcode_target(
            id = id,
            name = ctx.rule.attr.name,
            label = label,
            configuration = configuration,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = product,
            is_swift = is_swift,
            build_settings = build_settings,
            search_paths = search_paths,
            modulemaps = modulemaps,
            swiftmodules = process_swiftmodules(swift_info = swift_info),
            inputs = inputs,
            linker_inputs = linker_inputs,
            info_plist = None,
            dependencies = dependencies,
            outputs = outputs,
        ),
    )
