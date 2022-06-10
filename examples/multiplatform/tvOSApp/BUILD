load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:experimental.bzl",
    "xcode_provisioning_profile",
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
        "cpu": "tvos_arm64",
    },
)

tvos_application(
    name = "tvOSApp",
    bundle_id = "io.buildbuddy.example",
    bundle_name = "tvOSApp",
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    resources = [":ResourceGroup"],
    visibility = ["//visibility:public"],
    deps = [":tvOSApp.library"],
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "tvOS Team Provisioning Profile: io.buildbuddy.example",
    tags = ["manual"],
    team_id = "V82V4GQZXM",
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(["Assets.xcassets/**"]),
)

swift_library(
    name = "tvOSApp.library",
    srcs = glob(["**/*.swift"]),
    data = select({
        ":release_build": [],
        "//conditions:default": [":PreviewContent"],
    }),
    module_name = "iOSApp",
    tags = ["manual"],
    deps = [
        "//examples/multiplatform/Lib",
    ],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)
