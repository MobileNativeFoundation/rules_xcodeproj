load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_application")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:experimental.bzl",
    "xcode_provisioning_profile",
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
    bundle_id = "io.buildbuddy.example.watch",
    extension = "//examples/multiplatform/watchOSAppExtension",
    infoplists = [":Info.plist"],
    minimum_os_version = "7.0",
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    version = "//examples/multiplatform/iOSApp:Version",
    visibility = ["//visibility:public"],
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: io.buildbuddy.example.watch",
    tags = ["manual"],
    team_id = "V82V4GQZXM",
)

filegroup(
    name = "AppIcon.xcassets",
    srcs = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
)
