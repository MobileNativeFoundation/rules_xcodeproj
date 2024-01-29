""" Functions for processing top level targets """

load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(
    "//xcodeproj/internal:build_settings.bzl",
    "get_product_module_name",
    "get_targeted_device_family",
)
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
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_LIST",
    "memory_efficient_depset",
)
load("//xcodeproj/internal:opts.bzl", "process_opts")
load("//xcodeproj/internal:platforms.bzl", "platforms")
load("//xcodeproj/internal:product.bzl", "process_product")
load("//xcodeproj/internal:provisioning_profiles.bzl", "provisioning_profiles")
load("//xcodeproj/internal:target_id.bzl", "get_id")
load("//xcodeproj/internal:xcodeprojinfo.bzl", "XcodeProjInfo")
load("//xcodeproj/internal/files:app_icons.bzl", "app_icons")
load("//xcodeproj/internal/files:files.bzl", "build_setting_path", "join_paths_ignoring_empty")
load("//xcodeproj/internal/files:info_plists.bzl", "info_plists")
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

def _get_codesign_opts(*, ctx, inputs_attr, opts_attr, rule_attr):
    if not opts_attr:
        return ([], [])

    opts = [
        ctx.expand_make_variables(opts_attr, opt, {})
        for opt in getattr(rule_attr, opts_attr, [])
    ]

    if opts and inputs_attr:
        inputs = getattr(ctx.rule.files, inputs_attr, [])
    else:
        inputs = []

    return (opts, inputs)

def process_top_level_properties(
        *,
        target_name,
        target_files,
        bundle_info,
        build_settings):
    """Processes properties for a top level target.

    Args:
        target_name: Name of the target.
        target_files: The `files` attribute of the target.
        bundle_info: The `AppleBundleInfo` provider for the target.
        build_settings: A mutable `dict` of build settings.

    Returns:
        A `struct` of information about the top level target.
    """
    if bundle_info:
        bundle_extension = bundle_info.bundle_extension
        bundle_name = bundle_info.bundle_name
        executable_name = getattr(bundle_info, "executable_name", bundle_name)
        product_name = bundle_name
        product_type = bundle_info.product_type

        bundle_file = bundle_info.archive
        if bundle_file:
            bundle_path = bundle_file.path
        elif product_type.startswith("com.apple.product-type.framework"):
            # Some rules only set the binary for static frameworks. Create the
            # values that should be set (since we don't copy the product anyway)
            bundle_file = bundle_info.binary
            bundle_path = (
                "{}/{}.framework".format(bundle_file.dirname, product_name)
            )
        else:
            fail("`AppleBundleInfo.archive` not set for {}".format(target_name))

        set_if_true(
            build_settings,
            "PRODUCT_BUNDLE_IDENTIFIER",
            getattr(bundle_info, "bundle_id", None),
        )
        set_if_true(
            build_settings,
            "APPLICATION_EXTENSION_API_ONLY",
            getattr(bundle_info, "extension_safe", False),
        )
    else:
        bundle_extension = None
        bundle_name = None
        executable_name = target_name
        product_name = target_name

        bundle_file = None
        for file in target_files:
            if ".xctest/" in file.path:
                bundle_file = file
                break
        if bundle_file:
            # This is something like `swift_test`: it creates an xctest bundle
            product_type = "com.apple.product-type.bundle.unit-test"

            # "some/test.xctest/binary" -> "some/test.xctest"
            xctest_path = bundle_file.path
            bundle_path = xctest_path[:-(len(xctest_path.split(".xctest/")[1]) + 1)]
        else:
            product_type = "com.apple.product-type.tool"
            bundle_path = None

    return struct(
        bundle_extension = bundle_extension,
        bundle_file = bundle_file,
        bundle_name = bundle_name,
        bundle_path = bundle_path,
        executable_name = executable_name,
        product_name = product_name,
        product_type = product_type,
    )

# API

def _process_legacy_top_level_target(
        *,
        ctx,
        build_mode,
        target,
        attrs,
        automatic_target_info,
        bundle_info,
        rule_attr,
        transitive_infos):
    """Gathers information about a top-level target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        bundle_info: The `AppleBundleInfo` provider for `target`, or `None`.
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

    frameworks = getattr(rule_attr, "frameworks", [])
    framework_infos = [
        framework[XcodeProjInfo]
        for framework in frameworks
    ]
    avoid_deps = list(frameworks)

    test_host_target = getattr(rule_attr, "test_host", None)
    test_host_target_info = (
        test_host_target[XcodeProjInfo] if test_host_target else None
    )
    test_host = (
        test_host_target_info.xcode_target.id if test_host_target_info else None
    )
    if test_host_target:
        avoid_deps.append(test_host_target)

    app_clip_targets = getattr(rule_attr, "app_clips", [])
    app_clips = [
        extension_target[XcodeProjInfo].xcode_target.id
        for extension_target in app_clip_targets
    ]

    watch_app_target = getattr(rule_attr, "watch_application", None)
    watch_app_target_info = (
        watch_app_target[XcodeProjInfo] if watch_app_target else None
    )
    watch_application = (
        watch_app_target_info.xcode_target.id if watch_app_target_info else None
    )

    extension_targets = list(getattr(rule_attr, "extensions", []))
    extension_target = getattr(rule_attr, "extension", None)
    if extension_target:
        extension_targets.append(extension_target)
    extension_target_infos = [
        extension_target[XcodeProjInfo]
        for extension_target in extension_targets
    ]
    extensions = [info.xcode_target.id for info in extension_target_infos]

    hosted_targets = [
        struct(
            host = id,
            hosted = info.xcode_target.id,
        )
        for info in extension_target_infos
    ]

    additional_files = []
    build_settings = {}
    is_bundle = bundle_info != None
    cc_info = target[CcInfo] if CcInfo in target else None
    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    modulemaps = process_modulemaps(swift_info = swift_info)

    app_icon_info = app_icons.get_info(
        ctx = ctx,
        automatic_target_info = automatic_target_info,
        rule_attr = rule_attr,
    )
    infoplist = info_plists.adjust_for_xcode(
        info_plists.get_file(target),
        app_icon_info.default_icon_path if app_icon_info else None,
        ctx = ctx,
        rule_attr = rule_attr,
    )

    if infoplist:
        build_settings["INFOPLIST_FILE"] = build_setting_path(
            file = infoplist,
        )
        additional_files.append(infoplist)

    is_app_extension = bundle_info and bundle_info.bundle_extension == ".appex"

    infoplists_attrs = automatic_target_info.infoplists
    if infoplists_attrs and is_app_extension:
        extension_infoplists = [
            struct(
                id = id,
                infoplist = infoplist,
            )
            for attr in infoplists_attrs
            for infoplist in getattr(ctx.rule.files, attr, [])
        ]
    else:
        extension_infoplists = None

    provisioning_profiles.legacy_process_attr(
        automatic_target_info = automatic_target_info,
        build_settings = build_settings,
        objc_fragment = ctx.fragments.objc,
        rule_attr = rule_attr,
    )

    # The common case is to have a `bundle_info`, so this check prevents
    # expanding the `depset` unless needed. Yes, this uses knowledge of what
    # `process_top_level_properties` and `output_files.collect` does internally.
    target_files = EMPTY_LIST if bundle_info else target.files.to_list()

    props = process_top_level_properties(
        target_name = rule_attr.name,
        target_files = target_files,
        bundle_info = bundle_info,
        build_settings = build_settings,
    )
    platform = platforms.collect(ctx = ctx)

    direct_dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
        test_host = test_host,
        top_level_product_type = props.product_type,
        transitive_infos = transitive_infos,
    )

    avoid_compilation_providers_list = [
        (info.xcode_target, info.compilation_providers)
        for info in framework_infos
    ]

    if (test_host_target_info and
        props.product_type == "com.apple.product-type.bundle.unit-test"):
        avoid_compilation_providers_list.append(
            (
                test_host_target_info.xcode_target,
                test_host_target_info.compilation_providers,
            ),
        )

    if avoid_compilation_providers_list:
        (avoid_compilation_providers, _) = compilation_providers.merge(
            propagate_providers = True,
            transitive_compilation_providers = avoid_compilation_providers_list,
        )
    else:
        avoid_compilation_providers = None

    if apple_common.AppleDynamicFramework in target:
        apple_dynamic_framework_info = (
            target[apple_common.AppleDynamicFramework]
        )
    else:
        apple_dynamic_framework_info = None

    deps_infos = [
        dep[XcodeProjInfo]
        for attr in automatic_target_info.deps
        for dep in getattr(rule_attr, attr, [])
        if XcodeProjInfo in dep
    ]

    (
        target_compilation_providers,
        provider_compilation_providers,
    ) = compilation_providers.merge(
        apple_dynamic_framework_info = apple_dynamic_framework_info,
        cc_info = cc_info,
        propagate_providers = True,
        transitive_compilation_providers = [
            (info.xcode_target, info.compilation_providers)
            for info in deps_infos
        ] + avoid_compilation_providers_list,
    )
    linker_inputs = linker_input_files.collect(
        automatic_target_info = automatic_target_info,
        avoid_compilation_providers = avoid_compilation_providers,
        compilation_providers = target_compilation_providers,
        target = target,
        is_top_level = True,
    )

    codesign_opts, codesign_inputs = _get_codesign_opts(
        ctx = ctx,
        inputs_attr = automatic_target_info.codesign_inputs,
        opts_attr = automatic_target_info.codesignopts,
        rule_attr = rule_attr,
    )
    additional_files.extend(codesign_inputs)
    set_if_true(
        build_settings,
        "OTHER_CODE_SIGN_FLAGS",
        tuple(codesign_opts),
    )

    module_name_attribute, product_module_name = get_product_module_name(
        rule_attr = rule_attr,
        target = target,
    )

    product = process_product(
        actions = ctx.actions,
        bin_dir_path = bin_dir_path,
        bundle_extension = props.bundle_extension,
        bundle_file = props.bundle_file,
        bundle_name = props.bundle_name,
        bundle_path = props.bundle_path,
        executable_name = props.executable_name,
        # For bundle targets, we want to use the product name instead of
        # `module_name`
        module_name_attribute = (
            props.product_name if is_bundle else module_name_attribute
        ),
        product_name = props.product_name,
        product_type = props.product_type,
        linker_inputs = linker_inputs,
        target = target,
    )

    (target_inputs, provider_inputs) = input_files.collect(
        ctx = ctx,
        target = target,
        attrs = attrs,
        rule_attr = rule_attr,
        id = id,
        platform = platform,
        is_bundle = is_bundle,
        product = product,
        linker_inputs = linker_inputs,
        automatic_target_info = automatic_target_info,
        additional_files = additional_files,
        modulemaps = modulemaps,
        transitive_infos = transitive_infos,
        avoid_deps = avoid_deps,
    )
    debug_outputs = target[apple_common.AppleDebugOutputs] if apple_common.AppleDebugOutputs in target else None
    output_group_info = target[OutputGroupInfo] if OutputGroupInfo in target else None
    (target_outputs, provider_outputs) = output_files.collect(
        ctx = ctx,
        copy_product_transitively = True,
        debug_outputs = debug_outputs,
        id = id,
        inputs = target_inputs,
        output_group_info = output_group_info,
        product = product,
        swift_info = swift_info,
        infoplist = infoplist,
        rule_attr = rule_attr,
        transitive_infos = transitive_infos,
    )

    if target_inputs.entitlements:
        build_settings["CODE_SIGN_ENTITLEMENTS"] = build_setting_path(
            file = target_inputs.entitlements,
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
        # We don't actually merge the compilation context here, because no
        # top-level rules have (or will need) implementation deps
        implementation_compilation_context = (
            cc_info.compilation_context if cc_info else None
        ),
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    if not target_inputs.srcs:
        potential_target_merges = [
            struct(
                src = mergeable_target,
                dest = id,
            )
            for info in deps_infos
            for mergeable_target in info.mergable_xcode_library_targets.to_list()
        ]
    else:
        potential_target_merges = None

    set_if_true(
        build_settings,
        "TARGETED_DEVICE_FAMILY",
        get_targeted_device_family(getattr(ctx.rule.attr, "families", [])),
    )

    cpp = ctx.fragments.cpp

    # We don't have access to `CcInfo`/`SwiftInfo` here, so we have to make
    # a best guess at `-g` being used
    # We don't set "DEBUG_INFORMATION_FORMAT" for "dwarf", as we set that at
    # the project level.
    if cpp.apple_generate_dsym:
        if build_mode == "xcode":
            build_settings["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
        else:
            # Set to dwarf, because Bazel will generate the dSYMs
            # We don't set "DEBUG_INFORMATION_FORMAT" to "dwarf", as we set
            # that at the project level
            pass
    elif not ctx.var["COMPILATION_MODE"] == "dbg":
        build_settings["DEBUG_INFORMATION_FORMAT"] = ""

    set_if_true(
        build_settings,
        "PRODUCT_MODULE_NAME",
        product_module_name,
    )

    swiftmodules = process_swiftmodules(swift_info = swift_info)
    lldb_context = lldb_contexts.collect(
        build_mode = build_mode,
        id = id,
        is_swift = bool(swift_params),
        swift_sub_params = swift_sub_params,
        swiftmodules = swiftmodules,
        transitive_infos = deps_infos,
    )

    set_if_true(
        build_settings,
        "ASSETCATALOG_COMPILER_APPICON_NAME",
        app_icon_info.set_name if app_icon_info else None,
    )

    return processed_targets.make(
        compilation_providers = provider_compilation_providers,
        direct_dependencies = direct_dependencies,
        extension_infoplists = extension_infoplists,
        hosted_targets = hosted_targets,
        inputs = provider_inputs,
        is_top_level = not is_app_extension,
        is_xcode_required = True,
        lldb_context = lldb_context,
        outputs = provider_outputs,
        potential_target_merges = potential_target_merges,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_targets.make(
            id = id,
            label = label,
            configuration = configuration,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = product,
            test_host = test_host,
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
            watch_application = watch_application,
            extensions = extensions,
            app_clips = app_clips,
            direct_dependencies = direct_dependencies,
            transitive_dependencies = transitive_dependencies,
            outputs = target_outputs,
            lldb_context = lldb_context,
            xcode_required_targets = memory_efficient_depset(
                transitive = [
                    info.xcode_required_targets
                    for info in transitive_infos
                ],
            ),
        ),
    )

legacy_top_level_targets = struct(
    process = _process_legacy_top_level_target,
)
