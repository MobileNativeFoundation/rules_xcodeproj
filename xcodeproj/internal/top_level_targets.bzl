""" Functions for processing top level targets """

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":app_icons.bzl", "app_icons")
load(
    ":build_settings.bzl",
    "get_product_module_name",
    "get_targeted_device_family",
)
load(":collections.bzl", "set_if_true")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":configuration.bzl", "get_configuration")
load(":files.bzl", "file_path", "join_paths_ignoring_empty")
load(":info_plists.bzl", "info_plists")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":lldb_contexts.bzl", "lldb_contexts")
load(":opts.bzl", "process_opts")
load(":output_files.bzl", "output_files")
load(":platform.bzl", "platform_info")
load(":processed_target.bzl", "processed_target")
load(":product.bzl", "process_product")
load(":providers.bzl", "XcodeProjInfo")
load(":provisioning_profiles.bzl", "provisioning_profiles")
load(":target_id.bzl", "get_id")
load(
    ":target_properties.bzl",
    "process_codesignopts",
    "process_defines",
    "process_dependencies",
    "process_modulemaps",
    "process_swiftmodules",
    "should_bundle_resources",
    "should_include_outputs",
    "should_include_outputs_output_groups",
)
load(":target_search_paths.bzl", "target_search_paths")
load(":xcode_targets.bzl", "xcode_targets")

def get_tree_artifact_enabled(*, ctx, bundle_info):
    """Returns whether tree artifacts are enabled.

    Args:
        ctx: The context
        bundle_info: An instance of `BundleInfo`

    Returns:
        A boolean representing if tree artifacts are enabled
    """
    if not bundle_info:
        return False

    tree_artifact_enabled = (
        ctx.var.get("apple.experimental.tree_artifact_outputs", "")
            .lower() in
        ("true", "yes", "1")
    )

    return tree_artifact_enabled

def process_top_level_properties(
        *,
        target_name,
        target_files,
        bundle_info,
        tree_artifact_enabled,
        build_settings):
    """Processes properties for a top level target.

    Args:
        target_name: Name of the target.
        target_files: The `files` attribute of the target.
        bundle_info: The `AppleBundleInfo` provider for the target.
        tree_artifact_enabled: A `bool` controlling if tree artifacts are
            enabled.
        build_settings: A mutable `dict` of build settings.

    Returns:
        A `struct` of information about the top level target.
    """
    if bundle_info:
        bundle_name = bundle_info.bundle_name
        executable_name = getattr(bundle_info, "executable_name", bundle_name)
        product_name = bundle_name
        product_type = bundle_info.product_type

        bundle_file = bundle_info.archive

        bundle_file = bundle_info.archive
        if bundle_file:
            archive_file_path = file_path(bundle_file)

            if tree_artifact_enabled:
                bundle_file_path = archive_file_path
            else:
                bundle_extension = bundle_info.bundle_extension
                bundle = "{}{}".format(bundle_name, bundle_extension)
                if bundle_extension == ".app":
                    bundle_path = paths.join(
                        bundle_info.archive_root,
                        "Payload",
                        bundle,
                    )
                else:
                    bundle_path = paths.join(bundle_info.archive_root, bundle)
                bundle_file_path = file_path(
                    bundle_file,
                    path = bundle_path,
                )
        elif product_type.startswith("com.apple.product-type.framework"):
            # Some rules only set the binary for static frameworks
            bundle_file = bundle_info.binary
            archive_file_path = file_path(
                bundle_file,
                path = bundle_file.dirname,
            )
            bundle_file_path = archive_file_path
        else:
            fail("`AppleBundleInfo.archive` not set for {}".format(target_name))

        build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = bundle_info.bundle_id
        set_if_true(
            build_settings,
            "APPLICATION_EXTENSION_API_ONLY",
            getattr(bundle_info, "extension_safe", False),
        )
    else:
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
            path = xctest_path[:-(len(xctest_path.split(".xctest/")[1]) + 1)]
            bundle_file_path = file_path(
                bundle_file,
                path = path,
            )
            archive_file_path = bundle_file_path
        else:
            product_type = "com.apple.product-type.tool"
            bundle_file_path = None
            archive_file_path = None

    return struct(
        archive_file_path = archive_file_path,
        bundle_file = bundle_file,
        bundle_file_path = bundle_file_path,
        executable_name = executable_name,
        product_name = product_name,
        product_type = product_type,
    )

def process_top_level_target(
        *,
        ctx,
        target,
        automatic_target_info,
        bundle_info,
        transitive_infos):
    """Gathers information about a top-level target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        bundle_info: The `AppleBundleInfo` provider for `target`, or `None`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    configuration = get_configuration(ctx)
    label = target.label
    id = get_id(label = label, configuration = configuration)
    dependencies, transitive_dependencies = process_dependencies(
        automatic_target_info = automatic_target_info,
        transitive_infos = transitive_infos,
    )

    frameworks = getattr(ctx.rule.attr, "frameworks", [])
    framework_infos = [
        framework[XcodeProjInfo]
        for framework in frameworks
    ]
    avoid_deps = list(frameworks)

    test_host_target = getattr(ctx.rule.attr, "test_host", None)
    test_host_target_info = (
        test_host_target[XcodeProjInfo] if test_host_target else None
    )
    test_host = (
        test_host_target_info.xcode_target.id if test_host_target_info else None
    )
    if test_host_target:
        avoid_deps.append(test_host_target)

    app_clip_targets = getattr(ctx.rule.attr, "app_clips", [])
    app_clips = [
        extension_target[XcodeProjInfo].xcode_target.id
        for extension_target in app_clip_targets
    ]

    watch_app_target = getattr(ctx.rule.attr, "watch_application", None)
    watch_app_target_info = (
        watch_app_target[XcodeProjInfo] if watch_app_target else None
    )
    watch_application = (
        watch_app_target_info.xcode_target.id if watch_app_target_info else None
    )

    extension_targets = getattr(ctx.rule.attr, "extensions", [])
    extension_target = getattr(ctx.rule.attr, "extension", None)
    if extension_target:
        extension_targets.append(extension_target)
    extension_target_infos = [
        extension_target[XcodeProjInfo]
        for extension_target in extension_targets
    ]
    extensions = [info.xcode_target.id for info in extension_target_infos]

    hosted_target_infos = extension_target_infos
    if watch_app_target_info:
        hosted_target_infos.append(watch_app_target_info)
    hosted_targets = [
        struct(
            host = id,
            hosted = info.xcode_target.id,
        )
        for info in hosted_target_infos
    ]

    additional_files = []
    build_settings = {}
    is_bundle = bundle_info != None
    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None

    modulemaps = process_modulemaps(swift_info = swift_info)
    additional_files.extend(list(modulemaps.files))

    app_icon_info = app_icons.get_info(ctx, automatic_target_info)

    if automatic_target_info.alternate_icons:
        additional_files.extend(
            getattr(
                ctx.rule.files,
                automatic_target_info.alternate_icons,
                [],
            ),
        )

    infoplist = info_plists.adjust_for_xcode(
        info_plists.get_file(target),
        app_icon_info.default_icon_path if app_icon_info else None,
        ctx = ctx,
    )
    if infoplist:
        additional_files.append(infoplist)

    infoplists_attrs = automatic_target_info.infoplists
    if (infoplists_attrs and bundle_info and
        bundle_info.bundle_extension == ".appex"):
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

    provisioning_profiles.process_attr(
        ctx = ctx,
        automatic_target_info = automatic_target_info,
        build_settings = build_settings,
    )

    bundle_resources = should_bundle_resources(ctx = ctx)

    # The common case is to have a `bundle_info`, so this check prevents
    # expanding the `depset` unless needed. Yes, this uses knowledge of what
    # `process_top_level_properties` and `output_files.collect` does internally.
    target_files = [] if bundle_info else target.files.to_list()

    tree_artifact_enabled = get_tree_artifact_enabled(
        ctx = ctx,
        bundle_info = bundle_info,
    )
    props = process_top_level_properties(
        target_name = ctx.rule.attr.name,
        target_files = target_files,
        bundle_info = bundle_info,
        tree_artifact_enabled = tree_artifact_enabled,
        build_settings = build_settings,
    )
    platform = platform_info.collect(ctx = ctx)

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
        avoid_compilation_providers = comp_providers.merge(
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
        for dep in getattr(ctx.rule.attr, attr, [])
    ]

    compilation_providers = comp_providers.merge(
        apple_dynamic_framework_info = apple_dynamic_framework_info,
        cc_info = target[CcInfo] if CcInfo in target else None,
        swift_info = target[SwiftInfo] if SwiftInfo in target else None,
        transitive_compilation_providers = [
            (info.xcode_target, info.compilation_providers)
            for info in (deps_infos + framework_infos)
        ],
    )
    linker_inputs = linker_input_files.collect(
        ctx = ctx,
        compilation_providers = compilation_providers,
        avoid_compilation_providers = avoid_compilation_providers,
    )

    product = process_product(
        ctx = ctx,
        target = target,
        product_name = props.product_name,
        product_type = props.product_type,
        bundle_file = props.bundle_file,
        bundle_file_path = props.bundle_file_path,
        archive_file_path = props.archive_file_path,
        executable_name = props.executable_name,
        linker_inputs = linker_inputs,
    )

    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        id = id,
        platform = platform,
        is_bundle = is_bundle,
        product = product,
        linker_inputs = linker_inputs,
        bundle_resources = bundle_resources,
        automatic_target_info = automatic_target_info,
        additional_files = additional_files,
        transitive_infos = transitive_infos,
        avoid_deps = avoid_deps,
    )
    outputs = output_files.collect(
        id = id,
        swift_info = swift_info,
        top_level_product = product,
        infoplist = infoplist,
        transitive_infos = transitive_infos,
        should_produce_dto = should_include_outputs(ctx = ctx),
        should_produce_output_groups = should_include_outputs_output_groups(
            ctx = ctx,
        ),
    )

    if not inputs.srcs:
        xcode_library_targets = comp_providers.get_xcode_library_targets(
            compilation_providers = compilation_providers,
        )
        potential_target_merges = [
            struct(
                src = struct(
                    id = mergeable_target.id,
                    product_path = mergeable_target.product.file_path,
                ),
                dest = id,
            )
            for mergeable_target in xcode_library_targets
        ]
    else:
        potential_target_merges = None

    set_if_true(
        build_settings,
        "TARGETED_DEVICE_FAMILY",
        get_targeted_device_family(getattr(ctx.rule.attr, "families", [])),
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

    # We don't have access to `CcInfo`/`SwiftInfo` here, so we have to make
    # a best guess at `-g` being used
    # We don't set "DEBUG_INFORMATION_FORMAT" for "dwarf"-with-dsym",
    # as that's Xcode's default
    if not ctx.var["COMPILATION_MODE"] == "dbg":
        build_settings["DEBUG_INFORMATION_FORMAT"] = ""
    elif not cpp.apple_generate_dsym:
        build_settings["DEBUG_INFORMATION_FORMAT"] = "dwarf"

    set_if_true(
        build_settings,
        "PRODUCT_MODULE_NAME",
        get_product_module_name(ctx = ctx, target = target),
    )

    codesignopts_attr_name = automatic_target_info.codesignopts
    if codesignopts_attr_name:
        codesignopts = getattr(
            ctx.rule.attr,
            automatic_target_info.codesignopts,
            None,
        )
        process_codesignopts(
            codesignopts = codesignopts,
            build_settings = build_settings,
        )
    process_defines(
        compilation_providers = compilation_providers,
        build_settings = build_settings,
    )
    search_paths = target_search_paths.make(
        compilation_providers = compilation_providers,
        bin_dir_path = ctx.bin_dir.path,
        opts_search_paths = opts_search_paths,
    )
    swiftmodules = process_swiftmodules(swift_info = swift_info)
    lldb_context = lldb_contexts.collect(
        compilation_mode = ctx.var["COMPILATION_MODE"],
        objc_fragment = ctx.fragments.objc,
        id = id,
        is_swift = is_swift,
        search_paths = search_paths,
        modulemaps = modulemaps,
        swiftmodules = swiftmodules,
        transitive_infos = deps_infos,
    )

    set_if_true(
        build_settings,
        "ASSETCATALOG_COMPILER_APPICON_NAME",
        app_icon_info.set_name if app_icon_info else None,
    )

    return processed_target(
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        extension_infoplists = extension_infoplists,
        hosted_targets = hosted_targets,
        inputs = inputs,
        is_top_level_target = True,
        is_xcode_required = True,
        lldb_context = lldb_context,
        outputs = outputs,
        potential_target_merges = potential_target_merges,
        search_paths = search_paths,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_targets.make(
            id = id,
            name = ctx.rule.attr.name,
            label = label,
            configuration = configuration,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = product,
            is_testonly = getattr(ctx.rule.attr, "testonly", False),
            is_swift = is_swift,
            test_host = test_host,
            build_settings = build_settings,
            search_paths = search_paths,
            modulemaps = modulemaps,
            swiftmodules = swiftmodules,
            inputs = inputs,
            linker_inputs = linker_inputs,
            infoplist = infoplist,
            watch_application = watch_application,
            extensions = extensions,
            app_clips = app_clips,
            dependencies = dependencies,
            transitive_dependencies = transitive_dependencies,
            outputs = outputs,
            lldb_context = lldb_context,
            xcode_required_targets = depset(
                transitive = [
                    info.xcode_required_targets
                    for attr, info in transitive_infos
                    if (info.target_type in
                        automatic_target_info.xcode_targets.get(attr, [None]))
                ],
            ),
        ),
    )
