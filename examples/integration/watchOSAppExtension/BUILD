load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_extension")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_provisioning_profile")
load(
    "//:xcodeproj_targets.bzl",
    "TEAMID",
    "WATCHOS_BUNDLE_ID",
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
        "cpu": "watchos_arm64_32",
    },
)

watchos_extension(
    name = "watchOSAppExtension",
    bundle_id = "{}.extension".format(WATCHOS_BUNDLE_ID),
    frameworks = ["//UI:UIFramework.watchOS"],
    infoplists = [":infoplist"],
    minimum_deployment_os_version = "8.0",
    minimum_os_version = "7.0",
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    resources = [":ResourceGroup"],
    version = "//iOSApp:Version",
    visibility = ["//watchOSApp:__subpackages__"],
    deps = [":watchOSAppExtension.library"],
)

genrule(
    name = "infoplist",
    srcs = ["Info.plist"],
    outs = ["Info.withbundleid.plist"],
    cmd = "sed 's/WATCHOS_BUNDLE_ID/{}/'  $< > $@".format(WATCHOS_BUNDLE_ID),
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: {}.extension".format(WATCHOS_BUNDLE_ID),
    tags = ["manual"],
    team_id = TEAMID,
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(["Assets.xcassets/**"]),
)

swift_library(
    name = "watchOSAppExtension.library",
    srcs = ["watchOSApp.swift"],
    copts = ["-application-extension"],
    module_name = "watchOSAppExtension",
    tags = ["manual"],
    deps = ["//UI"],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)
