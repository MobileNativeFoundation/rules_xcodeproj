"""Functions for processing top level targets."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleResourceInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load("//xcodeproj/internal:app_icons.bzl", "app_icons")
load(
    "//xcodeproj/internal:build_settings.bzl",
    "get_product_module_name",
    "get_targeted_device_family",
)
load("//xcodeproj/internal:configuration.bzl", "calculate_configuration")
load("//xcodeproj/internal:info_plists.bzl", "info_plists")
load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_LIST",
    "EMPTY_STRING",
    "memory_efficient_depset",
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
load(":product.bzl", "PRODUCT_TYPE_ENCODED", "process_product")
load(":providers.bzl", "XcodeProjInfo")
load(":provisioning_profiles.bzl", "provisioning_profiles")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "process_modulemaps",
)
load(":xcode_targets.bzl", "xcode_targets")

_FRAMEWORK_PRODUCT_TYPE = "f"  # com.apple.product-type.framework
_UNIT_TEST_PRODUCT_TYPE = "u"  # com.apple.product-type.bundle.unit-test
_WATCHKIT_APP_PRODUCT_TYPE = "w"  # com.apple.product-type.application.watchapp2
_WATCHKIT_EXTENSION_PRODUCT_TYPE = "W"  # com.apple.product-type.watchkit2-extension

_BUNDLE_TYPES = {
    "A": None,  # com.apple.product-type.application.on-demand-install-capable
    "B": None,  # com.apple.product-type.bundle
    "E": None,  # com.apple.product-type.extensionkit-extension
    "U": None,  # com.apple.product-type.bundle.ui-testing
    "W": None,  # com.apple.product-type.watchkit2-extension
    "a": None,  # com.apple.product-type.application
    "e": None,  # com.apple.product-type.app-extension
    "f": None,  # com.apple.product-type.framework
    "m": None,  # com.apple.product-type.app-extension.messages
    "t": None,  # com.apple.product-type.tv-app-extension
    "u": None,  # com.apple.product-type.bundle.unit-test
    "w": None,  # com.apple.product-type.application.watchapp2
}

_PREVIEWS_ENABLED_PRODUCT_TYPES = {
    "A": None,  # com.apple.product-type.application.on-demand-install-capable
    "E": None,  # com.apple.product-type.extensionkit-extension
    "W": None,  # com.apple.product-type.watchkit2-extension
    "a": None,  # com.apple.product-type.application
    "e": None,  # com.apple.product-type.app-extension
    "f": None,  # com.apple.product-type.framework
    "m": None,  # com.apple.product-type.app-extension.messages
    "t": None,  # com.apple.product-type.tv-app-extension
    "u": None,  # com.apple.product-type.bundle.unit-test
    "w": None,  # com.apple.product-type.application.watchapp2
}

_TEST_HOST_PRODUCT_TYPES = {
    "A": None,  # com.apple.product-type.application.on-demand-install-capable
    "E": None,  # com.apple.product-type.extensionkit-extension
    "M": None,  # com.apple.product-type.application.messages
    "a": None,  # com.apple.product-type.application
    "e": None,  # com.apple.product-type.app-extension
    "m": None,  # com.apple.product-type.app-extension.messages
    "t": None,  # com.apple.product-type.tv-app-extension
    "w": None,  # com.apple.product-type.application.watchapp2
}

# FIXME: Exclude `avoid_deps`?
def _calculate_mergeable_info(
        *,
        deps_infos,
        dynamic_frameworks,
        id,
        product_type,
        target_inputs):
    # We can only merge if this target doesn't have its own sources
    if target_inputs.srcs or target_inputs.non_arc_srcs:
        return None

    mergeable_infos = depset(
        transitive = [
            info.mergeable_infos
            for info in deps_infos
        ],
    ).to_list()

    if len(mergeable_infos) == 1:
        # We can always add merge targets of a single library dependency
        mergeable_info = mergeable_infos[0]

        if not mergeable_info.id:
            # `None` for `id` means the library target was explicitly unfocused
            return None

        if mergeable_info.swiftmodule:
            return _swift_mergeable_info(
                dynamic_frameworks = dynamic_frameworks,
                id = id,
                mergeable_info = mergeable_info,
                product_type = product_type,
            )
        else:
            return _cc_mergeable_info(
                id = id,
                mergeable_info = mergeable_info,
            )

    if len(mergeable_infos) == 2:
        # Only merge if one src is Swift and the other isn't
        mergeable_info1 = mergeable_infos[0]
        mergeable_info2 = mergeable_infos[1]

        if not mergeable_info1.id and not mergeable_info2.id:
            # `None` for `id` means the library target was explicitly unfocused
            return None

        mergeable_info1_is_swift = mergeable_info1.swiftmodule
        mergeable_info2_is_swift = mergeable_info2.swiftmodule

        # Only merge 1 Swift and 1 non-Swift target for now
        if ((mergeable_info1_is_swift and mergeable_info2_is_swift) or
            (not mergeable_info1_is_swift and not mergeable_info2_is_swift)):
            return None

        cc = mergeable_info1 if mergeable_info2_is_swift else mergeable_info2
        swift = mergeable_info1 if mergeable_info1_is_swift else mergeable_info2

        if not cc.id:
            return _swift_mergeable_info(
                dynamic_frameworks = dynamic_frameworks,
                id = id,
                mergeable_info = swift,
                product_type = product_type,
            )
        if not swift.id:
            return _cc_mergeable_info(
                id = id,
                mergeable_info = cc,
            )

        previews_info = _previews_info(
            swift,
            dynamic_frameworks = dynamic_frameworks,
            product_type = product_type,
        )

        return struct(
            compile_target_ids = swift.id + " " + cc.id,
            conly_args = cc.params.conly_args,
            cxx_args = cc.params.cxx_args,
            extra_file_paths = memory_efficient_depset(
                transitive = [
                    swift.inputs.extra_file_paths,
                    cc.inputs.extra_file_paths,
                ],
            ),
            extra_files = memory_efficient_depset(
                transitive = [
                    swift.inputs.extra_files,
                    cc.inputs.extra_files,
                ],
            ),
            indexstores = list(swift.indexstores) + list(cc.indexstores),
            ids = [(id, (swift.id, cc.id))],
            module_name = swift.module_name,
            non_arc_srcs = cc.inputs.non_arc_srcs,
            package_bin_dir = swift.package_bin_dir,
            previews_dynamic_frameworks = previews_info.frameworks,
            previews_include_path = previews_info.include_path,
            product_files = (
                swift.product_file,
                cc.product_file,
            ),
            srcs = memory_efficient_depset(
                transitive = [
                    swift.inputs.srcs,
                    cc.inputs.srcs,
                ],
            ),
            swift_args = swift.params.swift_args,
            swift_debug_settings_to_merge = memory_efficient_depset(
                transitive = [
                    mergeable_infos[0].swift_debug_settings,
                    mergeable_infos[1].swift_debug_settings,
                ],
                order = "topological",
            ),
        )

    # Unmergeable source target count
    return None

def _calculate_product_type(*, target_files, bundle_info):
    """Calculates the product type for a top level target.

    Args:
        target_files: The `files` attribute of the target.
        bundle_info: The `AppleBundleInfo` provider for the target.
    """
    if bundle_info:
        return PRODUCT_TYPE_ENCODED[bundle_info.product_type]

    for file in target_files:
        if ".xctest/" in file.path:
            # This is something like `swift_test`: it creates an xctest bundle
            return "u"  # com.apple.product-type.bundle.unit-test

    return "T"  # com.apple.product-type.tool

def _compute_enabled_features(*, requested_features, unsupported_features):
    """Returns a list of features for the given build.

    Args:
        requested_features: A list of features requested. Typically from
            `ctx.features`.
        unsupported_features: A list of features to ignore. Typically from
            `ctx.disabled_features`.

    Returns:
        A set (`dict` of `None`) containing the subset of features that should
        be used.
    """
    unsupported_features = {f: None for f in unsupported_features}
    enabled_features = {
        f: None
        for f in requested_features
        if f not in unsupported_features
    }
    return enabled_features

def _cc_mergeable_info(*, id, mergeable_info):
    return struct(
        compile_target_ids = mergeable_info.id,
        conly_args = mergeable_info.params.conly_args,
        cxx_args = mergeable_info.params.cxx_args,
        extra_file_paths = mergeable_info.inputs.extra_file_paths,
        extra_files = mergeable_info.inputs.extra_files,
        indexstores = mergeable_info.indexstores,
        ids = [(id, (mergeable_info.id,))],
        module_name = mergeable_info.module_name,
        non_arc_srcs = mergeable_info.inputs.non_arc_srcs,
        package_bin_dir = EMPTY_STRING,
        previews_dynamic_frameworks = EMPTY_LIST,
        previews_include_path = EMPTY_STRING,
        product_files = (mergeable_info.product_file,),
        srcs = mergeable_info.inputs.srcs,
        swift_args = EMPTY_LIST,
        swift_debug_settings_to_merge = mergeable_info.swift_debug_settings,
    )

def _lldb_context_key(*, platform, product):
    fp = product.file_path
    if not fp:
        return None

    product_basename = paths.basename(fp)
    base_key = "{} {}".format(
        platforms.to_lldb_context_triple(platform),
        product_basename,
    )

    if not product.type in _BUNDLE_TYPES:
        return base_key

    executable_name = product.executable_name
    if not executable_name:
        executable_name = paths.split_extension(product_basename)[0]

    if platforms.is_platform_type(
        platform,
        apple_common.platform_type.macos,
    ):
        return "{}/Contents/MacOS/{}".format(base_key, executable_name)

    return "{}/{}".format(base_key, executable_name)

def _previews_info(
        mergeable_info,
        *,
        dynamic_frameworks,
        product_type):
    if not product_type in _PREVIEWS_ENABLED_PRODUCT_TYPES:
        return struct(
            frameworks = EMPTY_LIST,
            include_path = EMPTY_STRING,
        )

    if mergeable_info.swiftmodule:
        include_path = mergeable_info.swiftmodule.dirname
    else:
        include_path = EMPTY_STRING

    if product_type != _FRAMEWORK_PRODUCT_TYPE:
        dynamic_frameworks = EMPTY_LIST

    return struct(
        frameworks = dynamic_frameworks,
        include_path = include_path,
    )

def _swift_mergeable_info(
        *,
        dynamic_frameworks,
        id,
        mergeable_info,
        product_type):
    previews_info = _previews_info(
        mergeable_info,
        dynamic_frameworks = dynamic_frameworks,
        product_type = product_type,
    )

    return struct(
        compile_target_ids = mergeable_info.id,
        conly_args = EMPTY_LIST,
        cxx_args = EMPTY_LIST,
        extra_file_paths = mergeable_info.inputs.extra_file_paths,
        extra_files = mergeable_info.inputs.extra_files,
        indexstores = mergeable_info.indexstores,
        ids = [(id, (mergeable_info.id,))],
        module_name = mergeable_info.module_name,
        non_arc_srcs = EMPTY_DEPSET,
        package_bin_dir = mergeable_info.package_bin_dir,
        previews_dynamic_frameworks = previews_info.frameworks,
        previews_include_path = previews_info.include_path,
        product_files = (mergeable_info.product_file,),
        srcs = mergeable_info.inputs.srcs,
        swift_args = mergeable_info.params.swift_args,
        swift_debug_settings_to_merge = mergeable_info.swift_debug_settings,
    )

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
        tree_artifact_enabled):
    """Processes properties for a top level target.

    Args:
        target_name: Name of the target.
        target_files: The `files` attribute of the target.
        bundle_info: The `AppleBundleInfo` provider for the target.
        tree_artifact_enabled: A `bool` controlling if tree artifacts are
            enabled.

    Returns:
        A `struct` of information about the top level target.
    """
    if bundle_info:
        bundle_name = bundle_info.bundle_name
        executable_name = getattr(bundle_info, "executable_name", bundle_name)
        product_name = bundle_name
        product_type = bundle_info.product_type

        bundle_file = bundle_info.archive
        if bundle_file:
            bundle_path = bundle_file.path
            archive_file_path = bundle_path

            if tree_artifact_enabled:
                bundle_file_path = archive_file_path
            else:
                bundle_extension = bundle_info.bundle_extension
                bundle = "{}{}".format(bundle_name, bundle_extension)
                if bundle_extension == ".app":
                    bundle_file_path_path = paths.join(
                        bundle_info.archive_root,
                        "Payload",
                        bundle,
                    )
                else:
                    bundle_file_path_path = paths.join(
                        bundle_info.archive_root,
                        bundle,
                    )
                bundle_file_path = bundle_file_path_path
        elif product_type.startswith("com.apple.product-type.framework"):
            # Some rules only set the binary for static frameworks. Create the
            # values that should be set (since we don't copy the product anyway)
            bundle_file = bundle_info.binary
            bundle_path = (
                "{}/{}.framework".format(bundle_file.dirname, product_name)
            )
            archive_file_path = bundle_path
            bundle_file_path = archive_file_path
        else:
            fail("`AppleBundleInfo.archive` not set for {}".format(target_name))

        bundle_id = getattr(bundle_info, "bundle_id", None)
        extension_safe = getattr(bundle_info, "extension_safe", False)

    else:
        product_name = target_name
        executable_name = target_name
        extension_safe = False
        bundle_id = None

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
            bundle_file_path = bundle_path
            archive_file_path = bundle_file_path
        else:
            product_type = "com.apple.product-type.tool"
            bundle_path = None
            bundle_file_path = None
            archive_file_path = None

    return struct(
        archive_file_path = archive_file_path,
        bundle_file = bundle_file,
        bundle_path = bundle_path,
        bundle_file_path = bundle_file_path,
        bundle_id = bundle_id,
        extension_safe = extension_safe,
        executable_name = executable_name,
        product_name = product_name,
        product_type = PRODUCT_TYPE_ENCODED[product_type],
    )

def process_top_level_target(
        *,
        ctx,
        build_mode,
        target,
        attrs,
        automatic_target_info,
        generate_target,
        transitive_infos):
    """Gathers information about a top-level target.

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

    frameworks = getattr(ctx.rule.attr, "frameworks", [])
    framework_infos = [
        framework[XcodeProjInfo]
        for framework in frameworks
    ]
    avoid_deps = list(frameworks)

    test_host_target = getattr(ctx.rule.attr, "test_host", None)
    test_host_info = (
        test_host_target[XcodeProjInfo] if test_host_target else None
    )
    test_host = (
        test_host_info.xcode_target.id if test_host_info else None
    )
    if test_host_target:
        avoid_deps.append(test_host_target)

    bundle_info = target[AppleBundleInfo] if AppleBundleInfo in target else None

    # The common case is to have a `bundle_info`, so this check prevents
    # expanding the `depset` unless needed. Yes, this uses knowledge of what
    # `_calculate_product_type/process_top_level_properties` and
    # `output_files.collect` does internally.
    target_files = EMPTY_LIST if bundle_info else target.files.to_list()

    product_type = _calculate_product_type(
        bundle_info = bundle_info,
        target_files = target_files,
    )

    if not generate_target and product_type in _TEST_HOST_PRODUCT_TYPES:
        generate_target = True
        remove_if_not_test_host = True
    else:
        remove_if_not_test_host = False

    dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
        top_level_product_type = product_type,
        test_host = test_host,
        transitive_infos = transitive_infos,
    )

    avoid_compilation_providers_list = [
        (info.xcode_target, info.compilation_providers)
        for info in framework_infos
    ]

    if test_host_info and product_type == _UNIT_TEST_PRODUCT_TYPE:
        avoid_compilation_providers_list.append(
            (
                test_host_info.xcode_target,
                test_host_info.compilation_providers,
            ),
        )

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
        if XcodeProjInfo in dep
    ]

    compilation_providers = comp_providers.merge(
        apple_dynamic_framework_info = apple_dynamic_framework_info,
        cc_info = target[CcInfo] if CcInfo in target else None,
        transitive_compilation_providers = [
            (info.xcode_target, info.compilation_providers)
            for info in deps_infos
        ] + avoid_compilation_providers_list,
    )

    platform = platforms.collect(ctx = ctx)

    # FIXME: Extract
    # Take the most recent target with the same label
    focused_deps = {
        s.label: s.id
        for s in depset(
            order = "postorder",
            transitive = [
                info.focused_deps
                for info in transitive_infos
            ],
        ).to_list()
    }

    top_level_focused_deps = [
        struct(
            id = id,
            label = str(label),
            deps = tuple([
                struct(id = id, label = label)
                for label, id in focused_deps.items()
            ]),
        ),
    ]

    extension_targets = getattr(ctx.rule.attr, "extensions", [])
    extension_target = getattr(ctx.rule.attr, "extension", None)
    if extension_target:
        extension_targets.append(extension_target)
    extension_infos = [
        extension_target[XcodeProjInfo]
        for extension_target in extension_targets
    ]

    top_level_infos = framework_infos + extension_infos
    if test_host_info:
        top_level_infos.append(test_host_info)

    if generate_target:
        return _process_focused_top_level_target(
            ctx = ctx,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            avoid_compilation_providers_list = avoid_compilation_providers_list,
            avoid_deps = avoid_deps,
            bundle_info = bundle_info,
            build_mode = build_mode,
            compilation_providers = compilation_providers,
            configuration = configuration,
            dependencies = dependencies,
            deps_infos = deps_infos,
            extension_infos = extension_infos,
            id = id,
            label = label,
            platform = platform,
            product_type = product_type,
            remove_if_not_test_host = remove_if_not_test_host,
            target = target,
            target_files = target_files,
            test_host = test_host,
            top_level_focused_deps = top_level_focused_deps,
            top_level_infos = top_level_infos,
            transitive_dependencies = transitive_dependencies,
            transitive_infos = transitive_infos,
        )
    else:
        return _process_unfocused_top_level_target(
            ctx = ctx,
            avoid_deps = avoid_deps,
            build_mode = build_mode,
            bundle_info = bundle_info,
            compilation_providers = compilation_providers,
            dependencies = dependencies,
            deps_infos = deps_infos,
            is_bundle = bundle_info != None,
            label = label,
            platform = platform,
            product_type = product_type,
            target = target,
            target_files = target_files,
            top_level_focused_deps = top_level_focused_deps,
            top_level_infos = top_level_infos,
            transitive_dependencies = transitive_dependencies,
            transitive_infos = transitive_infos,
        )

def should_skip_codesigning(
        *,
        ctx,
        bundle_info,
        is_missing_provisioning_profile,
        platform):
    """Returns whether we should skip cosigning for this target.

    Args:
        ctx: The aspect context.
        bundle_info: An instance of `BundleInfo`.
        is_missing_provisioning_profile: Whether a provisioning profile is
            is able to be set on the target, and it's missing.
        platform: A value returned from `platforms.collect`.

    Returns:
        A `bool` indicating if we should skip codesigning.
    """
    if not bundle_info:
        return False

    if (is_missing_provisioning_profile and
        bundle_info.product_type == "com.apple.product-type.framework"):
        return True

    if not platforms.is_simulator(platform):
        return (is_missing_provisioning_profile and
                platforms.is_not_macos(platform))

    enabled_features = _compute_enabled_features(
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    return "apple.skip_codesign_simulator_bundles" in enabled_features

def _process_focused_top_level_target(
        *,
        ctx,
        attrs,
        automatic_target_info,
        avoid_compilation_providers_list,
        avoid_deps,
        build_mode,
        bundle_info,
        compilation_providers,
        configuration,
        dependencies,
        deps_infos,
        extension_infos,
        id,
        label,
        platform,
        product_type,
        remove_if_not_test_host,
        target,
        target_files,
        test_host,
        top_level_focused_deps,
        top_level_infos,
        transitive_dependencies,
        transitive_infos):
    if avoid_compilation_providers_list:
        avoid_compilation_providers = comp_providers.merge(
            transitive_compilation_providers = avoid_compilation_providers_list,
        )
    else:
        avoid_compilation_providers = None

    linker_inputs = linker_input_files.collect(
        target = target,
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
        is_top_level = True,
        avoid_compilation_providers = avoid_compilation_providers,
    )

    module_name_attribute, module_name = get_product_module_name(
        ctx = ctx,
        target = target,
    )

    is_bundle = bundle_info != None

    props = process_top_level_properties(
        target_name = ctx.rule.attr.name,
        target_files = target_files,
        bundle_info = bundle_info,
        tree_artifact_enabled = get_tree_artifact_enabled(
            ctx = ctx,
            bundle_info = bundle_info,
        ),
    )

    product = process_product(
        ctx = ctx,
        label = label,
        target = target,
        product_name = props.product_name,
        product_type = product_type,
        module_name = module_name,
        module_name_attribute = (
            props.product_name if is_bundle else module_name_attribute
        ),
        bundle_file = props.bundle_file,
        bundle_path = props.bundle_path,
        bundle_file_path = props.bundle_file_path,
        archive_file_path = props.archive_file_path,
        executable_name = props.executable_name,
        linker_inputs = linker_inputs,
    )

    framework_product_mappings = [
        (file, product.file)
        for file in product.framework_files.to_list()
    ]

    app_icon_info = app_icons.get_info(ctx, automatic_target_info)
    infoplist = info_plists.adjust_for_xcode(
        info_plists.get_file(target),
        app_icon_info.default_icon_path if app_icon_info else None,
        ctx = ctx,
    )

    additional_files = []
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

    provisioning_profile_props = provisioning_profiles.process_attr(
        automatic_target_info = automatic_target_info,
        objc_fragment = ctx.fragments.objc,
        rule_attr = ctx.rule.attr,
    )

    (target_inputs, provider_inputs) = input_files.collect(
        ctx = ctx,
        build_mode = build_mode,
        target = target,
        attrs = attrs,
        id = id,
        platform = platform,
        is_resource_bundle_consuming = (
            is_bundle and AppleResourceInfo in target
        ),
        product = product,
        linker_inputs = linker_inputs,
        automatic_target_info = automatic_target_info,
        additional_files = additional_files,
        transitive_infos = transitive_infos,
        avoid_deps = avoid_deps,
    )

    mergeable_info = _calculate_mergeable_info(
        deps_infos = deps_infos,
        dynamic_frameworks = linker_inputs._top_level_values.dynamic_frameworks,
        id = id,
        product_type = product_type,
        target_inputs = target_inputs,
    )

    actual_package_bin_dir = join_paths_ignoring_empty(
        ctx.bin_dir.path,
        label.workspace_root,
        label.package,
    )

    if mergeable_info:
        package_bin_dir = mergeable_info.package_bin_dir
        params = struct(
            conly_args = mergeable_info.conly_args,
            cxx_args = mergeable_info.cxx_args,
            swift_args = mergeable_info.swift_args,
        )

        if mergeable_info.previews_dynamic_frameworks:
            framework_product_map = {
                linker_file: product_file
                for linker_file, product_file in depset(
                    transitive = [
                        info.framework_product_mappings
                        for info in transitive_infos
                    ],
                ).to_list()
            }

            previews_dynamic_frameworks = []
            for linker_file in mergeable_info.previews_dynamic_frameworks:
                product_file = framework_product_map.get(linker_file)
                if product_file:
                    previews_dynamic_frameworks.append((product_file, True))
                else:
                    previews_dynamic_frameworks.append((linker_file, False))
        else:
            previews_dynamic_frameworks = EMPTY_LIST

        swift_debug_settings_to_merge = (
            mergeable_info.swift_debug_settings_to_merge
        )

        indexstore_override_path = actual_package_bin_dir + "/" + label.name
        indexstore_overrides = [
            (indexstore, indexstore_override_path)
            for indexstore in mergeable_info.indexstores
        ]
    else:
        package_bin_dir = actual_package_bin_dir
        params = opts.collect_params(
            c_sources = target_inputs.c_sources,
            cxx_sources = target_inputs.cxx_sources,
            target = target,
        )
        previews_dynamic_frameworks = EMPTY_LIST
        indexstore_overrides = []

        # FIXME: Exclude `avoid_deps`
        swift_debug_settings_to_merge = memory_efficient_depset(
            transitive = [
                info.swift_debug_settings
                for info in deps_infos
            ],
            order = "topological",
        )

    (
        target_build_settings,
        swift_debug_settings_file,
        params_files,
    ) = pbxproj_partials.write_target_build_settings(
        actions = ctx.actions,
        apple_generate_dsym = ctx.fragments.cpp.apple_generate_dsym,
        certificate_name = provisioning_profile_props.certificate_name,
        colorize = ctx.attr._colorize[BuildSettingInfo].value,
        conly_args = params.conly_args,
        cxx_args = params.cxx_args,
        device_family = get_targeted_device_family(
            getattr(ctx.rule.attr, "families", []),
        ),
        entitlements = target_inputs.entitlements,
        extension_safe = props.extension_safe,
        generate_build_settings = True,
        include_self_swift_debug_settings = not mergeable_info,
        infoplist = infoplist,
        is_top_level_target = True,
        name = label.name,
        previews_dynamic_frameworks = previews_dynamic_frameworks,
        previews_include_path = (
            mergeable_info.previews_include_path if mergeable_info else EMPTY_STRING
        ),
        provisioning_profile_is_xcode_managed = (
            provisioning_profile_props.is_xcode_managed
        ),
        provisioning_profile_name = provisioning_profile_props.name,
        skip_codesigning = should_skip_codesigning(
            ctx = ctx,
            bundle_info = bundle_info,
            is_missing_provisioning_profile = (
                provisioning_profile_props.is_missing_profile
            ),
            platform = platform,
        ),
        swift_args = params.swift_args,
        swift_debug_settings_to_merge = swift_debug_settings_to_merge,
        team_id = provisioning_profile_props.team_id,
        tool = ctx.executable._target_build_settings_generator,
    )

    swift_debug_settings = memory_efficient_depset(
        [
            (
                _lldb_context_key(platform = platform, product = product),
                swift_debug_settings_file,
            ),
        ],
        transitive = [
            info.swift_debug_settings
            for info in top_level_infos
        ],
    )

    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    bwx_output_groups = bwx_ogroups.collect(
        build_mode = build_mode,
        id = id,
        target_inputs = target_inputs,
        modulemaps = process_modulemaps(swift_info = swift_info),
        params_files = params_files,
        transitive_infos = transitive_infos,
    )

    if apple_common.AppleDebugOutputs in target:
        debug_outputs = target[apple_common.AppleDebugOutputs]
    else:
        debug_outputs = None

    (
        target_outputs,
        provider_outputs,
        bwb_output_groups_metadata,
    ) = output_files.collect(
        actions = ctx.actions,
        copy_product_transitively = True,
        debug_outputs = debug_outputs,
        id = id,
        indexstore_overrides = indexstore_overrides,
        infoplist = infoplist,
        name = label.name,
        output_group_info = (
            target[OutputGroupInfo] if OutputGroupInfo in target else None
        ),
        product = product,
        swift_info = swift_info,
        transitive_infos = transitive_infos,
    )

    bwb_output_groups = bwb_ogroups.collect(
        bwx_output_groups = bwx_output_groups,
        metadata = bwb_output_groups_metadata,
        transitive_infos = transitive_infos,
    )

    focused_extension_infos = [
        info
        for info in extension_infos
        if info.xcode_target
    ]

    if product_type == _WATCHKIT_APP_PRODUCT_TYPE:
        watchkit_extensions = [
            info.xcode_target.id
            for info in focused_extension_infos
            if info.xcode_target.product.type == (
                _WATCHKIT_EXTENSION_PRODUCT_TYPE
            )
        ]
        watchkit_extension = (
            watchkit_extensions[0] if watchkit_extensions else None
        )
    else:
        watchkit_extension = None

    hosted_targets = [
        struct(
            host = id,
            hosted = info.xcode_target.id,
        )
        for info in focused_extension_infos
    ]

    return processed_target(
        bwb_output_groups = bwb_output_groups,
        bwx_output_groups = bwx_output_groups,
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        extension_infoplists = extension_infoplists,
        framework_product_mappings = framework_product_mappings,
        hosted_targets = hosted_targets,
        inputs = provider_inputs,
        is_top_level = True,
        mergeable_infos = EMPTY_DEPSET,
        merged_target_ids = mergeable_info.ids if mergeable_info else None,
        outputs = provider_outputs,
        platform = platform.apple_platform,
        swift_debug_settings = EMPTY_DEPSET,
        top_level_focused_deps = top_level_focused_deps,
        top_level_swift_debug_settings = swift_debug_settings,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_targets.make(
            build_settings_file = target_build_settings,
            bundle_id = props.bundle_id,
            configuration = configuration,
            dependencies = dependencies,
            has_c_params = bool(params.conly_args),
            has_cxx_params = bool(params.cxx_args),
            id = id,
            inputs = target_inputs,
            label = label,
            linker_inputs = linker_inputs,
            mergeable_info = mergeable_info,
            outputs = target_outputs,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = product,
            remove_if_not_test_host = remove_if_not_test_host,
            test_host = test_host,
            transitive_dependencies = transitive_dependencies,
            watchkit_extension = watchkit_extension,
        ),
    )

def _process_unfocused_top_level_target(
        *,
        ctx,
        avoid_deps,
        build_mode,
        bundle_info,
        compilation_providers,
        dependencies,
        deps_infos,
        is_bundle,
        label,
        platform,
        product_type,
        target,
        target_files,
        top_level_focused_deps,
        top_level_infos,
        transitive_dependencies,
        transitive_infos):
    props = process_top_level_properties(
        target_name = ctx.rule.attr.name,
        target_files = target_files,
        bundle_info = bundle_info,
        tree_artifact_enabled = get_tree_artifact_enabled(
            ctx = ctx,
            bundle_info = bundle_info,
        ),
    )

    slim_product = process_product(
        ctx = ctx,
        label = label,
        target = target,
        product_name = props.product_name,
        product_type = product_type,
        module_name = None,
        module_name_attribute = None,
        bundle_file = props.bundle_file,
        bundle_path = props.bundle_path,
        bundle_file_path = props.bundle_file_path,
        archive_file_path = props.archive_file_path,
        executable_name = props.executable_name,
        linker_inputs = None,
    )

    framework_product_mappings = [
        (file, slim_product.file)
        for file in slim_product.framework_files.to_list()
    ]

    params = opts.collect_params(
        c_sources = None,
        cxx_sources = None,
        target = target,
    )
    swift_debug_settings_to_merge = memory_efficient_depset(
        transitive = [
            info.swift_debug_settings
            # FIXME: Exclude `avoid_deps`
            for info in deps_infos
        ],
        order = "topological",
    )

    (
        _,
        swift_debug_settings_file,
        _,
    ) = pbxproj_partials.write_target_build_settings(
        actions = ctx.actions,
        apple_generate_dsym = False,
        colorize = ctx.attr._colorize[BuildSettingInfo].value,
        conly_args = [],
        cxx_args = [],
        generate_build_settings = False,
        is_top_level_target = True,
        name = label.name,
        swift_args = params.swift_args,
        swift_debug_settings_to_merge = swift_debug_settings_to_merge,
        tool = ctx.executable._target_build_settings_generator,
    )

    swift_debug_settings = depset(
        [
            (
                _lldb_context_key(
                    platform = platform,
                    product = slim_product,
                ),
                swift_debug_settings_file,
            ),
        ],
        transitive = [
            info.swift_debug_settings
            for info in top_level_infos
        ],
    )

    if is_bundle and AppleResourceInfo in target:
        resource_info = target[AppleResourceInfo]
    else:
        resource_info = None

    provider_inputs = input_files.merge_top_level(
        avoid_deps = avoid_deps,
        build_mode = build_mode,
        label = label,
        platform = platform,
        resource_info = resource_info,
        transitive_infos = transitive_infos,
    )

    return processed_target(
        bwb_output_groups = bwb_ogroups.merge(
            transitive_infos = transitive_infos,
        ),
        bwx_output_groups = bwx_ogroups.merge(
            transitive_infos = transitive_infos,
        ),
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        framework_product_mappings = framework_product_mappings,
        hosted_targets = None,
        inputs = provider_inputs,
        is_top_level = True,
        mergeable_infos = EMPTY_DEPSET,
        merged_target_ids = None,
        outputs = output_files.merge(transitive_infos = transitive_infos),
        platform = platform.apple_platform,
        swift_debug_settings = EMPTY_DEPSET,
        top_level_focused_deps = top_level_focused_deps,
        top_level_swift_debug_settings = swift_debug_settings,
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
    )
