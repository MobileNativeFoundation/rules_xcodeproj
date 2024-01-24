"""Functions for processing top level targets."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "AppleResourceInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo", "SwiftProtoInfo")
load(
    "//xcodeproj/internal:build_settings.bzl",
    "get_product_module_name",
    "get_targeted_device_family",
)
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
    "EMPTY_DEPSET",
    "EMPTY_LIST",
    "EMPTY_STRING",
    "FALSE_ARG",
    "TRUE_ARG",
    "memory_efficient_depset",
)
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")
load("//xcodeproj/internal:platforms.bzl", "platforms")
load("//xcodeproj/internal:products.bzl", "PRODUCT_TYPE_ENCODED", "products")
load("//xcodeproj/internal:provisioning_profiles.bzl", "provisioning_profiles")
load("//xcodeproj/internal:target_id.bzl", "get_id")
load("//xcodeproj/internal:xcodeprojinfo.bzl", "XcodeProjInfo")
load("//xcodeproj/internal/files:app_icons.bzl", "app_icons")
load(
    "//xcodeproj/internal/files:incremental_input_files.bzl",
    input_files = "incremental_input_files",
)
load(
    "//xcodeproj/internal/files:incremental_output_files.bzl",
    "output_groups",
    output_files = "incremental_output_files",
)
load("//xcodeproj/internal/files:info_plists.bzl", "info_plists")
load("//xcodeproj/internal/files:linker_input_files.bzl", "linker_input_files")
load(
    ":incremental_processed_targets.bzl",
    processed_targets = "incremental_processed_targets",
)

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

def _cc_mergeable_info(*, id, mergeable_info):
    return struct(
        compile_target_ids = mergeable_info.id,
        conly_args = mergeable_info.args.conly,
        cxx_args = mergeable_info.args.cxx,
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

def _calculate_mergeable_info(
        *,
        avoid_deps,
        deps_infos,
        dynamic_frameworks,
        id,
        product_type,
        xcode_inputs):
    # We can only merge if this target doesn't have its own sources
    if xcode_inputs.srcs or xcode_inputs.non_arc_srcs:
        return None

    avoid_ids = {
        id: None
        for id in depset(
            transitive = [
                dep[XcodeProjInfo].transitive_dependencies
                for dep in avoid_deps
            ],
        ).to_list()
    }

    mergeable_infos = depset(
        transitive = [
            info.mergeable_infos
            for info in deps_infos
        ],
    ).to_list()
    mergeable_infos = [
        info
        for info in mergeable_infos
        if info.id not in avoid_ids
    ]

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
            conly_args = cc.args.conly,
            cxx_args = cc.args.cxx,
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
            swift_args = swift.args.swift,
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

def _create_link_params(
        *,
        actions,
        bin_dir_path,
        label,
        linker_inputs,
        merged_product_files,
        product,
        tool):
    if not linker_inputs:
        return None

    top_level_values = linker_inputs._top_level_values
    if not top_level_values:
        return None

    link_args = top_level_values.link_args

    if not link_args:
        return None

    target_name = label.name

    if merged_product_files:
        self_product_paths = [
            file.path
            for file in merged_product_files
            if file
        ]
    else:
        # Handle `{cc,swift}_{binary,test}` with `srcs` case
        self_product_paths = [
            paths.join(
                label.workspace_name,
                bin_dir_path,
                label.package,
                "lib{}.lo".format(target_name),
            ),
        ]

    generated_product_paths_file = actions.declare_file(
        "{}.rules_xcodeproj.generated_product_paths_file.json".format(
            target_name,
        ),
    )
    actions.write(
        output = generated_product_paths_file,
        content = json.encode(self_product_paths),
    )

    is_framework = (
        product.xcode_product.type == "com.apple.product-type.framework"
    )

    def _create_link_sub_params(idx, idx_link_args):
        output = actions.declare_file(
            "{}.rules_xcodeproj.link.sub-{}.params".format(
                target_name,
                idx,
            ),
        )
        actions.write(
            output = output,
            content = idx_link_args,
        )
        return output

    link_sub_params = [
        _create_link_sub_params(idx, idx_link_args)
        for idx, idx_link_args in enumerate(link_args)
    ]

    link_params = actions.declare_file(
        "{}.rules_xcodeproj.link.params".format(target_name),
    )

    args = actions.args()
    args.add(link_params)
    args.add(generated_product_paths_file)
    args.add(TRUE_ARG if is_framework else FALSE_ARG)
    args.add_all(link_sub_params)

    actions.run(
        executable = tool,
        arguments = [args],
        mnemonic = "ProcessLinkParams",
        progress_message = "Generating %{output}",
        inputs = (
            [generated_product_paths_file] +
            list(top_level_values.link_args_inputs)
        ) + link_sub_params,
        outputs = [link_params],
    )

    return link_params

def _lldb_context_key(*, platform, xcode_product):
    product_basename = xcode_product.original_basename
    if not product_basename:
        return None

    base_key = "{} {}".format(
        platforms.to_lldb_context_triple(platform),
        product_basename,
    )

    if not xcode_product.type in _BUNDLE_TYPES:
        return base_key

    executable_name = xcode_product.executable_name
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
        swift_args = mergeable_info.args.swift,
        swift_debug_settings_to_merge = mergeable_info.swift_debug_settings,
    )

def _process_focused_top_level_target(
        *,
        ctx,
        actions,
        attrs,
        automatic_target_info,
        avoid_deps,
        bin_dir_path,
        bundle_info,
        cc_info,
        configuration,
        deps_infos,
        direct_dependencies,
        extension_infos,
        id,
        label,
        platform,
        product_type,
        props,
        provider_compilation_providers,
        rule_attr,
        target,
        target_compilation_providers,
        test_host,
        top_level_focused_deps,
        top_level_infos,
        transitive_dependencies,
        transitive_infos,
        unfocus_if_not_test_host):
    linker_inputs = linker_input_files.collect(
        automatic_target_info = automatic_target_info,
        compilation_providers = target_compilation_providers,
        is_top_level = True,
        target = target,
    )

    is_bundle = bundle_info != None

    product = products.collect(
        actions = actions,
        bundle_extension = props.bundle_extension,
        bundle_file = props.bundle_file,
        bundle_name = props.bundle_name,
        bundle_path = props.bundle_path,
        executable_name = props.executable_name,
        linker_inputs = linker_inputs,
        product_name = props.product_name,
        product_type = product_type,
        target = target,
    )

    if target and apple_common.AppleDynamicFramework in target:
        framework_files = (
            target[apple_common.AppleDynamicFramework].framework_files
        )
        product_file = product.file
        framework_product_mappings = [
            (file, product_file)
            for file in framework_files.to_list()
        ]
    else:
        framework_files = EMPTY_DEPSET
        framework_product_mappings = EMPTY_LIST

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

    provisioning_profile_props = provisioning_profiles.incremental_process_attr(
        automatic_target_info = automatic_target_info,
        objc_fragment = ctx.fragments.objc,
        rule_attr = rule_attr,
    )

    (target_inputs, provider_inputs) = input_files.collect(
        ctx = ctx,
        attrs = attrs,
        automatic_target_info = automatic_target_info,
        avoid_deps = avoid_deps,
        cc_info = cc_info,
        framework_files = framework_files,
        id = id,
        infoplist = infoplist,
        label = label,
        linker_inputs = linker_inputs,
        platform = platform,
        resource_info = (
            target[AppleResourceInfo] if is_bundle and AppleResourceInfo in target else None
        ),
        rule_attr = rule_attr,
        swift_proto_info = (
            target[SwiftProtoInfo] if SwiftProtoInfo in target else None
        ),
        transitive_infos = transitive_infos,
    )

    mergeable_info = _calculate_mergeable_info(
        avoid_deps = avoid_deps,
        deps_infos = deps_infos,
        dynamic_frameworks = linker_inputs._top_level_values.dynamic_frameworks,
        id = id,
        product_type = product_type,
        xcode_inputs = target_inputs.xcode_inputs,
    )

    actual_package_bin_dir = products.calculate_packge_bin_dir(
        bin_dir_path = bin_dir_path,
        label = label,
    )

    if mergeable_info:
        package_bin_dir = mergeable_info.package_bin_dir
        args = struct(
            conly = mergeable_info.conly_args,
            cxx = mergeable_info.cxx_args,
            swift = mergeable_info.swift_args,
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
        args = compiler_args.collect(
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
        actions = actions,
        apple_generate_dsym = ctx.fragments.cpp.apple_generate_dsym,
        certificate_name = provisioning_profile_props.certificate_name,
        colorize = ctx.attr._colorize[BuildSettingInfo].value,
        conly_args = args.conly,
        cxx_args = args.cxx,
        device_family = get_targeted_device_family(
            getattr(rule_attr, "families", []),
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
        skip_codesigning = _should_skip_codesigning(
            ctx = ctx,
            bundle_info = bundle_info,
            is_missing_provisioning_profile = (
                provisioning_profile_props.is_missing_profile
            ),
            platform = platform,
        ),
        swift_args = args.swift,
        swift_debug_settings_to_merge = swift_debug_settings_to_merge,
        team_id = provisioning_profile_props.team_id,
        tool = ctx.executable._target_build_settings_generator,
    )

    xcode_product = product.xcode_product
    swift_debug_settings = memory_efficient_depset(
        [
            (
                _lldb_context_key(
                    platform = platform,
                    xcode_product = xcode_product,
                ),
                swift_debug_settings_file,
            ),
        ],
        transitive = [
            info.swift_debug_settings
            for info in top_level_infos
        ],
    )

    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    if apple_common.AppleDebugOutputs in target:
        debug_outputs = target[apple_common.AppleDebugOutputs]
    else:
        debug_outputs = None

    link_params = _create_link_params(
        actions = actions,
        bin_dir_path = bin_dir_path,
        label = label,
        tool = ctx.executable._link_params_processor,
        linker_inputs = linker_inputs,
        merged_product_files = (
            mergeable_info.product_files if mergeable_info else None
        ),
        product = product,
    )

    (
        target_outputs,
        provider_outputs,
        target_output_groups_metadata,
    ) = output_files.collect(
        actions = actions,
        compile_params_files = params_files,
        copy_product_transitively = True,
        debug_outputs = debug_outputs,
        id = id,
        indexstore_overrides = indexstore_overrides,
        infoplist = infoplist,
        link_params = link_params,
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

    module_name_attribute, module_name = get_product_module_name(
        rule_attr = rule_attr,
        target = target,
    )

    return processed_targets.make(
        compilation_providers = provider_compilation_providers,
        direct_dependencies = direct_dependencies,
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
        target_output_groups = target_output_groups,
        top_level_focused_deps = top_level_focused_deps,
        top_level_swift_debug_settings = swift_debug_settings,
        transitive_dependencies = transitive_dependencies,
        xcode_target = xcode_targets.make(
            build_settings_file = target_build_settings,
            bundle_id = props.bundle_id,
            configuration = configuration,
            direct_dependencies = direct_dependencies,
            has_c_params = bool(args.conly),
            has_cxx_params = bool(args.cxx),
            id = id,
            inputs = target_inputs.xcode_inputs,
            is_top_level = True,
            label = label,
            link_params = link_params,
            mergeable_info = mergeable_info,
            module_name = module_name,
            module_name_attribute = (
                props.product_name if is_bundle else module_name_attribute
            ),
            outputs = target_outputs,
            package_bin_dir = package_bin_dir,
            platform = platform,
            product = xcode_product,
            test_host = test_host,
            transitive_dependencies = transitive_dependencies,
            unfocus_if_not_test_host = unfocus_if_not_test_host,
            watchkit_extension = watchkit_extension,
        ),
    )

def _process_top_level_properties(
        *,
        target_name,
        target_files,
        bundle_info):
    """Processes properties for a top level target.

    Args:
        target_name: Name of the target.
        target_files: The `files` attribute of the target.
        bundle_info: The `AppleBundleInfo` provider for the target.

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

        bundle_id = getattr(bundle_info, "bundle_id", None)
        extension_safe = getattr(bundle_info, "extension_safe", False)
    else:
        bundle_extension = None
        bundle_id = None
        bundle_name = None
        executable_name = target_name
        extension_safe = False
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
        bundle_id = bundle_id,
        bundle_name = bundle_name,
        bundle_path = bundle_path,
        executable_name = executable_name,
        extension_safe = extension_safe,
        product_name = product_name,
        product_type = PRODUCT_TYPE_ENCODED[product_type],
    )

def _process_unfocused_top_level_target(
        *,
        ctx,
        actions,
        avoid_deps,
        direct_dependencies,
        deps_infos,
        is_bundle,
        label,
        platform,
        product_type,
        props,
        provider_compilation_providers,
        target,
        top_level_focused_deps,
        top_level_infos,
        transitive_dependencies,
        transitive_infos):
    slim_product = products.collect(
        actions = actions,
        bundle_extension = props.bundle_extension,
        bundle_file = props.bundle_file,
        bundle_name = props.bundle_name,
        bundle_path = props.bundle_path,
        executable_name = props.executable_name,
        linker_inputs = None,
        product_name = props.product_name,
        product_type = product_type,
        target = target,
    )

    if target and apple_common.AppleDynamicFramework in target:
        framework_files = (
            target[apple_common.AppleDynamicFramework].framework_files
        )
        slim_product_file = slim_product.file
        framework_product_mappings = [
            (file, slim_product_file)
            for file in framework_files.to_list()
        ]
    else:
        framework_product_mappings = EMPTY_LIST

    args = compiler_args.collect(
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
        actions = actions,
        apple_generate_dsym = False,
        colorize = ctx.attr._colorize[BuildSettingInfo].value,
        # FIXME: Should this be args.conly?
        conly_args = [],
        # FIXME: Should this be args.cxx?
        cxx_args = [],
        generate_build_settings = False,
        is_top_level_target = True,
        name = label.name,
        swift_args = args.swift,
        swift_debug_settings_to_merge = swift_debug_settings_to_merge,
        tool = ctx.executable._target_build_settings_generator,
    )

    xcode_product = slim_product.xcode_product
    swift_debug_settings = depset(
        [
            (
                _lldb_context_key(
                    platform = platform,
                    xcode_product = xcode_product,
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
        platform = platform,
        resource_info = resource_info,
        transitive_infos = transitive_infos,
    )

    return processed_targets.make(
        compilation_providers = provider_compilation_providers,
        direct_dependencies = direct_dependencies,
        framework_product_mappings = framework_product_mappings,
        hosted_targets = None,
        inputs = provider_inputs,
        is_top_level = True,
        mergeable_infos = EMPTY_DEPSET,
        merged_target_ids = None,
        outputs = output_files.merge(transitive_infos = transitive_infos),
        platform = platform.apple_platform,
        swift_debug_settings = EMPTY_DEPSET,
        target_output_groups = output_groups.merge(
            transitive_infos = transitive_infos,
        ),
        top_level_focused_deps = top_level_focused_deps,
        top_level_swift_debug_settings = swift_debug_settings,
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
    )

def _should_skip_codesigning(
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
        platform: A value from `platforms.collect`.

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

# API

def _process_incremental_top_level_target(
        *,
        ctx,
        target,
        attrs,
        automatic_target_info,
        generate_target,
        rule_attr,
        transitive_infos):
    """Gathers information about a top-level target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        generate_target: Whether an Xcode target should be generated for this
            target.
        rule_attr: `ctx.rule.attr`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        A value from `processed_target`.
    """
    bin_dir_path = ctx.bin_dir.path
    cc_info = target[CcInfo] if CcInfo in target else None
    configuration = calculate_configuration(bin_dir_path = bin_dir_path)
    label = automatic_target_info.label
    id = get_id(label = label, configuration = configuration)

    frameworks = getattr(rule_attr, "frameworks", [])
    framework_infos = [
        framework[XcodeProjInfo]
        for framework in frameworks
    ]
    avoid_deps = list(frameworks)

    test_host_target = getattr(rule_attr, "test_host", None)
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
        unfocus_if_not_test_host = True
    else:
        unfocus_if_not_test_host = False

    direct_dependencies, transitive_dependencies = dependencies.collect(
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
        for dep in getattr(rule_attr, attr, [])
        if XcodeProjInfo in dep
    ]

    (
        target_compilation_providers,
        provider_compilation_providers,
    ) = compilation_providers.merge(
        apple_dynamic_framework_info = apple_dynamic_framework_info,
        cc_info = cc_info,
        propagate_providers = compilation_providers.should_propagate_providers(
            product_type = product_type,
        ),
        transitive_compilation_providers = [
            (info.xcode_target, info.compilation_providers)
            for info in deps_infos
        ] + avoid_compilation_providers_list,
    )

    platform = platforms.collect(ctx = ctx)

    # FIXME: Extract
    # Take the most recent target with the same label
    focused_library_deps = {
        s.label: s.id
        for s in depset(
            order = "postorder",
            transitive = [
                info.focused_library_deps
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
                for label, id in focused_library_deps.items()
            ]),
        ),
    ]

    extension_targets = getattr(rule_attr, "extensions", [])
    extension_target = getattr(rule_attr, "extension", None)
    if extension_target:
        extension_targets.append(extension_target)
    extension_infos = [
        extension_target[XcodeProjInfo]
        for extension_target in extension_targets
    ]

    top_level_infos = framework_infos + extension_infos
    if test_host_info:
        top_level_infos.append(test_host_info)

    actions = ctx.actions
    name = rule_attr.name

    props = _process_top_level_properties(
        target_name = name,
        target_files = target_files,
        bundle_info = bundle_info,
    )

    if generate_target:
        return _process_focused_top_level_target(
            ctx = ctx,
            actions = actions,
            attrs = attrs,
            automatic_target_info = automatic_target_info,
            avoid_deps = avoid_deps,
            bin_dir_path = bin_dir_path,
            bundle_info = bundle_info,
            cc_info = cc_info,
            configuration = configuration,
            deps_infos = deps_infos,
            direct_dependencies = direct_dependencies,
            extension_infos = extension_infos,
            id = id,
            label = label,
            platform = platform,
            product_type = product_type,
            props = props,
            provider_compilation_providers = provider_compilation_providers,
            rule_attr = rule_attr,
            target = target,
            target_compilation_providers = target_compilation_providers,
            test_host = test_host,
            top_level_focused_deps = top_level_focused_deps,
            top_level_infos = top_level_infos,
            transitive_dependencies = transitive_dependencies,
            transitive_infos = transitive_infos,
            unfocus_if_not_test_host = unfocus_if_not_test_host,
        )
    else:
        return _process_unfocused_top_level_target(
            ctx = ctx,
            actions = actions,
            avoid_deps = avoid_deps,
            deps_infos = deps_infos,
            direct_dependencies = direct_dependencies,
            is_bundle = bundle_info != None,
            label = label,
            platform = platform,
            product_type = product_type,
            props = props,
            provider_compilation_providers = provider_compilation_providers,
            target = target,
            top_level_focused_deps = top_level_focused_deps,
            top_level_infos = top_level_infos,
            transitive_dependencies = transitive_dependencies,
            transitive_infos = transitive_infos,
        )

incremental_top_level_targets = struct(
    process = _process_incremental_top_level_target,
)
