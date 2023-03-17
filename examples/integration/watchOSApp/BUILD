load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_application")
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_provisioning_profile")
load(
    "//:xcodeproj_targets.bzl",
    "IOS_BUNDLE_ID",
    "TEAMID",
    "WATCHOS_BUNDLE_ID",
)

config_setting(
    name = "device_build",
    values = {
        "cpu": "watchos_arm64_32",
    },
)

watchos_application(
    name = "watchOSApp",
    app_icons = ["AppIcon.xcassets"],
    bundle_id = WATCHOS_BUNDLE_ID,
    extension = "//watchOSAppExtension",
    infoplists = [":infoplist"],
    minimum_os_version = "8.0",
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    version = "//iOSApp:Version",
    visibility = [
        "//iOSApp:__subpackages__",
        "//watchOSApp:__subpackages__",
    ],
)

genrule(
    name = "infoplist",
    srcs = ["Info.plist"],
    outs = ["Info.withbundleid.plist"],
    cmd = "sed 's/IOS_BUNDLE_ID/{}/'  $< > $@".format(IOS_BUNDLE_ID),
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: {}".format(WATCHOS_BUNDLE_ID),
    tags = ["manual"],
    team_id = TEAMID,
)

filegroup(
    name = "AppIcon.xcassets",
    srcs = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
)
