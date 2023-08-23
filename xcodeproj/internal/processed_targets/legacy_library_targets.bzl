"""Functions for processing library targets."""

load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load("//xcodeproj/internal:build_settings.bzl", "get_product_module_name")
load("//xcodeproj/internal:collections.bzl", "set_if_true")
load("//xcodeproj/internal:compilation_providers.bzl", "compilation_providers")
load("//xcodeproj/internal:configuration.bzl", "calculate_configuration")
load(
    "//xcodeproj/internal:legacy_target_properties.bzl",
    "process_dependencies",
    "process_modulemaps",
    "process_swiftmodules",
)
load(
    "//xcodeproj/internal:legacy_xcode_targets.bzl",
    xcode_targets = "legacy_xcode_targets",
)
load("//xcodeproj/internal:lldb_contexts.bzl", "lldb_contexts")
load("//xcodeproj/internal:opts.bzl", "process_opts")
load("//xcodeproj/internal:platforms.bzl", "platforms")
load("//xcodeproj/internal:product.bzl", "process_product")
load("//xcodeproj/internal:target_id.bzl", "get_id")
load("//xcodeproj/internal:xcodeprojinfo.bzl", "XcodeProjInfo")
load("//xcodeproj/internal/files:files.bzl", "build_setting_path", "join_paths_ignoring_empty")
load(
    "//xcodeproj/internal/files:legacy_input_files.bzl",
    input_files = "legacy_input_files",
)
load(
    "//xcodeproj/internal/files:legacy_output_files.bzl",
    output_files = "legacy_output_files",
)
load("//xcodeproj/internal/files:linker_input_files.bzl", "linker_input_files")
load(
    ":legacy_processed_targets.bzl",
    processed_targets = "legacy_processed_targets",
)

def _collect_cc_indexstores(target):
    """Gathers outputs with .indexstore extension from the target's transitive c language compile action outputs 
    """
    c_compile_actions = [action for action in target.actions if action.mnemonic in ("ObjcCompile", "CppCompile")]
    c_compile_action_outputs = [action.outputs for action in c_compile_actions]
    indexstores = [output for output in depset(transitive = c_compile_action_outputs).to_list() if output.extension == "indexstore"]
    return indexstores

def _process_legacy_library_target(
        *,
        ctx,
        build_mode,
        target,
        attrs,
        automatic_target_info,
        rule_attr,
        transitive_infos):
    """Gathers information about a library target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        rule_attr: `ctx.rule.attr`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        A value from `processed_target`.
    """
    bin_dir_path = ctx.bin_dir.path
    configuration = calculate_configuration(bin_dir_path = bin_dir_path)
    label = target.label
    id = get_id(label = label, configuration = configuration)

    build_settings = {}

    product_name = rule_attr.name
    module_name_attribute, product_module_name = get_product_module_name(
        rule_attr = rule_attr,
        target = target,
    )
    set_if_true(
        build_settings,
        "PRODUCT_MODULE_NAME",
        product_module_name,
    )

    direct_dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
        transitive_infos = transitive_infos,
    )

    deps_infos = [
        dep[XcodeProjInfo]
        for attr in automatic_target_info.implementation_deps
        for dep in getattr(rule_attr, attr, [])
        if XcodeProjInfo in dep
    ]

    cc_info = target[CcInfo]
    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    (
        target_compilation_providers,
        provider_compilation_providers,
    ) = compilation_providers.collect(
        cc_info = cc_info,
        objc = target[apple_common.Objc] if apple_common.Objc in target else None,
    )
    linker_inputs = linker_input_files.collect(
        target = target,
        automatic_target_info = automatic_target_info,
        compilation_providers = target_compilation_providers,
    )

    platform = platforms.collect(ctx = ctx)
    product = process_product(
        actions = ctx.actions,
        bin_dir_path = bin_dir_path,
        linker_inputs = linker_inputs,
        module_name_attribute = module_name_attribute,
        product_name = product_name,
        product_type = "com.apple.product-type.library.static",
        target = target,
    )

    modulemaps = process_modulemaps(swift_info = swift_info)
    (target_inputs, provider_inputs) = input_files.collect(
        ctx = ctx,
        target = target,
        attrs = attrs,
        rule_attr = rule_attr,
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
    c_indexstores = _collect_cc_indexstores(target)
        
    (target_outputs, provider_outputs) = output_files.collect(
        ctx = ctx,
        debug_outputs = debug_outputs,
        id = id,
        inputs = target_inputs,
        output_group_info = output_group_info,
        product = product,
        rule_attr = rule_attr,
        swift_info = swift_info,
        transitive_infos = transitive_infos,
        c_indexstores = c_indexstores,
    )

    if target_inputs.pch:
        build_settings["GCC_PREFIX_HEADER"] = build_setting_path(
            file = target_inputs.pch,
        )

    package_bin_dir = join_paths_ignoring_empty(
        bin_dir_path,
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
        implementation_compilation_context = compilation_providers.collect_implementation_compilation_context(
            cc_info = cc_info,
            transitive_implementation_providers = [
                info.compilation_providers
                for info in deps_infos
            ],
        ),
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

    return processed_targets.make(
        compilation_providers = provider_compilation_providers,
        direct_dependencies = direct_dependencies,
        inputs = provider_inputs,
        library = product.file,
        lldb_context = lldb_context,
        outputs = provider_outputs,
        transitive_dependencies = transitive_dependencies,
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
            direct_dependencies = direct_dependencies,
            transitive_dependencies = transitive_dependencies,
            outputs = target_outputs,
        ),
    )

legacy_library_targets = struct(
    process = _process_legacy_library_target,
)
