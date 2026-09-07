"""Processes raw Apple resource bundles for Xcode Preview materialization."""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@build_bazel_apple_support//lib:apple_support.bzl", "apple_support")
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleFrameworkBundleInfo",
    "AppleResourceInfo",
)
load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "resources_common",
)
load(
    "@build_bazel_rules_apple//apple/internal:apple_toolchains.bzl",
    "AppleMacToolsToolchainInfo",
)

XcodeProjPreviewResourceInfo = provider(
    doc = "A processed AppleResourceInfo produced only for Xcode Previews.",
    fields = {
        "resource_info": "The processed AppleResourceInfo.",
    },
)

def _aspect_attrs():
    return {
        "_mac_toolchain": attr.label(
            cfg = "exec",
            default = Label(
                "@build_bazel_rules_apple//apple/internal:mac_tools_toolchain",
            ),
            providers = [[AppleMacToolsToolchainInfo]],
        ),
    }

def _platform_prerequisites(ctx):
    target_os = apple_support.target_os_from_rule_ctx(ctx)
    target_environment = apple_support.target_environment_from_rule_ctx(ctx)
    disabled_features = {feature: None for feature in ctx.disabled_features}
    enabled_features = [
        feature
        for feature in ctx.features
        if feature not in disabled_features
    ]
    if target_os == "ios":
        platform = (
            apple_common.platform.ios_device if target_environment == "device" else apple_common.platform.ios_simulator
        )
    elif target_os == "macos":
        platform = apple_common.platform.macos
    elif target_os == "tvos":
        platform = (
            apple_common.platform.tvos_device if target_environment == "device" else apple_common.platform.tvos_simulator
        )
    elif target_os == "visionos":
        platform = (
            apple_common.platform.visionos_device if target_environment == "device" else apple_common.platform.visionos_simulator
        )
    elif target_os == "watchos":
        platform = (
            apple_common.platform.watchos_device if target_environment == "device" else apple_common.platform.watchos_simulator
        )
    else:
        fail("Unsupported Apple platform for Preview resources: {}".format(target_os))

    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    platform_type = getattr(apple_common.platform_type, target_os)
    minimum_os = str(xcode_config.minimum_os_for_platform_type(platform_type))
    device_families = {
        "ios": ["iphone", "ipad"],
        "macos": ["mac"],
        "tvos": ["tv"],
        "visionos": ["vision"],
        "watchos": ["watch"],
    }[target_os]
    return struct(
        apple_fragment = ctx.fragments.apple,
        build_settings = struct(),
        config_vars = ctx.var,
        cpp_fragment = ctx.fragments.cpp,
        device_families = device_families,
        features = enabled_features,
        minimum_deployment_os = minimum_os,
        minimum_os = minimum_os,
        objc_fragment = None,
        platform = platform,
        platform_type = platform_type,
        sdk_version = xcode_config.sdk_version_for_platform(platform),
        uses_swift = False,
        xcode_version_config = xcode_config,
    )

def _process(ctx):
    """Returns a Preview-only processed provider for an apple_resource_bundle."""
    owner = str(ctx.label)
    bundle_name = "{}.bundle".format(
        ctx.rule.attr.bundle_name or ctx.label.name,
    )
    bundle_id = ctx.rule.attr.bundle_id or (
        "com.bazel.apple_resource_bundle_{}".format(
            ctx.rule.attr.bundle_name or ctx.label.name,
        )
    )
    process_args = {
        "actions": ctx.actions,
        "apple_mac_toolchain_info": ctx.attr._mac_toolchain[AppleMacToolsToolchainInfo],
        "bundle_id": bundle_id,
        "output_discriminator": "rules_xcodeproj_{}".format(
            ctx.attr._generator_name,
        ),
        "platform_prerequisites": _platform_prerequisites(ctx),
        "processing_owner": owner,
        "product_type": None,
        "rule_label": ctx.label,
    }
    resource_infos = []

    infoplists = resources_common.collect(
        attr = ctx.rule.attr,
        res_attrs = ["infoplists"],
    )
    if not infoplists:
        infoplists = [ctx.file._preview_fallback_infoplist]

    if infoplists:
        bucketized_owners, unowned_resources, buckets = (
            resources_common.bucketize_typed_data(
                bucket_type = "infoplists",
                owner = owner,
                parent_dir_param = bundle_name,
                resources = infoplists,
            )
        )
        resource_infos.append(resources_common.process_bucketized_data(
            bucketized_owners = bucketized_owners,
            buckets = buckets,
            resource_types_to_process = ["infoplists"],
            unowned_resources = unowned_resources,
            **process_args
        ))

    resource_files = resources_common.collect(
        attr = ctx.rule.attr,
        res_attrs = ["resources"],
    )
    if resource_files:
        bucketized_owners, unowned_resources, buckets = (
            resources_common.bucketize_data(
                owner = owner,
                parent_dir_param = bundle_name,
                resources = resource_files,
            )
        )
        resource_infos.append(resources_common.process_bucketized_data(
            bucketized_owners = bucketized_owners,
            buckets = buckets,
            resource_types_to_process = [
                "asset_catalogs",
                "datamodels",
                "metals",
                "mlmodels",
                "plists",
                "pngs",
                "storyboards",
                "strings",
                "texture_atlases",
                "xcstrings",
                "xibs",
            ],
            unowned_resources = unowned_resources,
            **process_args
        ))

    structured_files = resources_common.collect(
        attr = ctx.rule.attr,
        res_attrs = ["structured_resources"],
    )
    if structured_files:
        structured_parent_dir = partial.make(
            resources_common.structured_resources_parent_dir,
            parent_dir = bundle_name,
            strip_prefixes = ctx.rule.attr.strip_structured_resources_prefixes,
        )
        bucketized_owners, unowned_resources, buckets = (
            resources_common.bucketize_data(
                allowed_buckets = ["strings", "plists", "xcstrings"],
                owner = owner,
                parent_dir_param = structured_parent_dir,
                resources = structured_files,
            )
        )
        resource_infos.append(resources_common.process_bucketized_data(
            bucketized_owners = bucketized_owners,
            buckets = buckets,
            resource_types_to_process = ["strings", "plists", "xcstrings"],
            unowned_resources = unowned_resources,
            **process_args
        ))

    inherited_infos = []
    for dep in ctx.rule.attr.resources:
        if AppleFrameworkBundleInfo in dep:
            continue
        if AppleResourceInfo in dep:
            inherited_infos.append(dep[AppleResourceInfo])
        elif XcodeProjPreviewResourceInfo in dep:
            inherited_infos.append(
                dep[XcodeProjPreviewResourceInfo].resource_info,
            )
    if inherited_infos:
        merged = resources_common.merge_providers(
            default_owner = owner,
            providers = inherited_infos,
        )
        resource_infos.append(resources_common.nest_in_bundle(
            nesting_bundle_dir = bundle_name,
            provider_to_nest = merged,
        ))

    if not resource_infos:
        return None
    return XcodeProjPreviewResourceInfo(
        resource_info = resources_common.merge_providers(
            default_owner = owner,
            providers = resource_infos,
        ),
    )

preview_resource_bundles = struct(
    aspect_attrs = _aspect_attrs,
    process = _process,
)
