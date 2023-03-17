load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_app_clip")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_provisioning_profile")
load(
    "//:xcodeproj_targets.bzl",
    "APP_CLIP_BUNDLE_ID",
    "IOS_BUNDLE_ID",
    "TEAMID",
)

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

config_setting(
    name = "device_build",
    values = {
        "cpu": "ios_arm64",
    },
)

ios_app_clip(
    name = "AppClip",
    app_icons = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
    bundle_id = APP_CLIP_BUNDLE_ID,
    bundle_name = "AppClip",
    entitlements = ":entitlements",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    resources = [":ResourceGroup"],
    version = "//iOSApp:Version",
    visibility = ["//iOSApp:__subpackages__"],
    deps = [":AppClip.library"],
)

genrule(
    name = "entitlements",
    srcs = ["Entitlements.entitlements"],
    outs = ["Entitlements.withbundleid.plist"],
    cmd = """
sed \
  -e 's/APP_CLIP_BUNDLE_ID/{}/g' \
  -e 's/IOS_BUNDLE_ID/{}/g' \
  -e 's/TEAMID/{}/g' $< > $@
""".format(
        APP_CLIP_BUNDLE_ID,
        IOS_BUNDLE_ID,
        TEAMID,
    ),
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: {}".format(APP_CLIP_BUNDLE_ID),
    tags = ["manual"],
    team_id = TEAMID,
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(
        [
            "Assets.xcassets/**",
        ],
        exclude = ["Assets.xcassets/AppIcon.appiconset/**"],
    ),
)

swift_library(
    name = "AppClip.library",
    srcs = glob(["**/*.swift"]),
    data = select({
        ":release_build": [],
        "//conditions:default": [":PreviewContent"],
    }),
    module_name = "AppClip",
    tags = ["manual"],
    deps = [
        "//Lib",
    ],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)
