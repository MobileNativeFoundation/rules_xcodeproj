""" Functions for processing top level targets """

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
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
load(":providers.bzl", "XcodeProjInfo")
load(":processed_target.bzl", "processed_target")
load(":product.bzl", "process_product")
load(":provisioning_profiles.bzl", "provisioning_profiles")
load(":target_search_paths.bzl", "target_search_paths")
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

    if not ctx.attr._archived_bundles_allowed[BuildSettingInfo].value:
        if not tree_artifact_enabled:
            fail("""\
Not using `--define=apple.experimental.tree_artifact_outputs=1` is slow. If \
you can't set that flag, you can set `archived_bundles_allowed = True` on the \
`xcodeproj` rule to have it unarchive bundles when installing them.
""")

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

        if tree_artifact_enabled:
            bundle_file_path = file_path(bundle_info.archive)
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
                bundle_info.archive,
                path = bundle_path,
            )

        build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = bundle_info.bundle_id
    else:
        executable_name = target_name
        product_name = target_name

        xctest = None
        for file in target_files:
            if ".xctest/" in file.path:
                xctest = file
                break
        if xctest:
            # This is something like `swift_test`: it creates an xctest bundle
            product_type = "com.apple.product-type.bundle.unit-test"

            # "some/test.xctest/binary" -> "some/test.xctest"
            xctest_path = xctest.path
            path = xctest_path[:-(len(xctest_path.split(".xctest/")[1]) + 1)]
            bundle_file_path = file_path(
                xctest,
                path = path,
            )
        else:
            product_type = "com.apple.product-type.tool"
            bundle_file_path = None

    return struct(
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

    test_host_target = getattr(ctx.rule.attr, "test_host", None)
    test_host_target_info = (
        test_host_target[XcodeProjInfo] if test_host_target else None
    )
    test_host = (
        test_host_target_info.xcode_target.id if test_host_target_info else None
    )
    avoid_deps = [test_host_target] if test_host_target else []

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

    infoplist = info_plists.adjust_for_xcode(
        info_plists.get_file(target),
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

    if (test_host_target_info and
        props.product_type == "com.apple.product-type.bundle.unit-test"):
        avoid_compilation_providers = (
            test_host_target_info.compilation_providers
        )
    else:
        avoid_compilation_providers = None

    if apple_common.Objc in target:
        objc = target[apple_common.Objc]
    else:
        objc = None

    compilation_providers = comp_providers.merge(
        cc_info = target[CcInfo] if CcInfo in target else None,
        objc = objc,
        swift_info = target[SwiftInfo] if SwiftInfo in target else None,
        transitive_compilation_providers = [
            (
                dep[XcodeProjInfo].xcode_target,
                dep[XcodeProjInfo].compilation_providers,
            )
            # TODO: Get attr name from `XcodeProjAutomaticTargetProcessingInfo`
            for dep in getattr(ctx.rule.attr, "deps", [])
        ],
    )
    linker_inputs = linker_input_files.collect(
        ctx = ctx,
        compilation_providers = compilation_providers,
        avoid_compilation_providers = avoid_compilation_providers,
    )

    inputs = input_files.collect(
        ctx = ctx,
        target = target,
        id = id,
        platform = platform,
        is_bundle = is_bundle,
        linker_inputs = linker_inputs,
        bundle_resources = bundle_resources,
        automatic_target_info = automatic_target_info,
        additional_files = additional_files,
        transitive_infos = transitive_infos,
        avoid_deps = avoid_deps,
    )
    outputs = output_files.collect(
        target_files = target_files,
        bundle_info = bundle_info,
        default_info = target[DefaultInfo],
        swift_info = swift_info,
        id = id,
        infoplist = infoplist,
        transitive_infos = transitive_infos,
        should_produce_dto = should_include_outputs(ctx = ctx),
        should_produce_output_groups = should_include_outputs_output_groups(
            ctx = ctx,
        ),
    )

    xcode_library_targets = comp_providers.get_xcode_library_targets(
        compilation_providers = compilation_providers,
    )
    if len(xcode_library_targets) == 1 and not inputs.srcs:
        mergeable_target = xcode_library_targets[0]
        mergeable_label = mergeable_target.label
        potential_target_merges = [struct(
            src = struct(
                id = mergeable_target.id,
                product_path = mergeable_target.product.path,
            ),
            dest = id,
        )]
    elif bundle_info and len(xcode_library_targets) > 1:
        fail("""\
The xcodeproj rule requires {} rules to have a single library dep. {} has {}.\
""".format(ctx.rule.kind, label, len(xcode_library_targets)))
    else:
        potential_target_merges = None
        mergeable_label = None

    non_mergable_targets = [
        library
        for library in linker_input_files.get_top_level_static_libraries(
            linker_inputs,
        )
        if mergeable_label and library.owner != mergeable_label
    ]

    set_if_true(
        build_settings,
        "TARGETED_DEVICE_FAMILY",
        get_targeted_device_family(getattr(ctx.rule.attr, "families", [])),
    )

    cpp = ctx.fragments.cpp

    # TODO: Get the value for device builds, even when active config is not for
    # device, as Xcode only uses this value for device builds
    build_settings["ENABLE_BITCODE"] = str(cpp.apple_bitcode_mode) != "none"

    # We don't have access to `CcInfo`/`SwiftInfo` here, so we have to make
    # a best guess at `-g` being used
    # We don't set "DEBUG_INFORMATION_FORMAT" for "dwarf"-with-dsym",
    # as that's Xcode's default
    if not ctx.var["COMPILATION_MODE"] == "dbg":
        build_settings["DEBUG_INFORMATION_FORMAT"] = ""
    elif not cpp.apple_generate_dsym:
        build_settings["DEBUG_INFORMATION_FORMAT"] = "dwarf"

    product = process_product(
        target = target,
        product_name = props.product_name,
        product_type = props.product_type,
        bundle_file_path = props.bundle_file_path,
        executable_name = props.executable_name,
        linker_inputs = linker_inputs,
    )

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
        transitive_infos = [
            info
            for attr, info in transitive_infos
            if (info.target_type in
                automatic_target_info.xcode_targets.get(attr, [None]))
        ],
    )

    return processed_target(
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        extension_infoplists = extension_infoplists,
        hosted_targets = hosted_targets,
        inputs = inputs,
        lldb_context = lldb_context,
        non_mergable_targets = non_mergable_targets,
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
        ),
    )
