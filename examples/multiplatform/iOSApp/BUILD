load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_apple//apple:versioning.bzl", "apple_bundle_version")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

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

apple_bundle_version(
    name = "Version",
    build_version = "123.4.5",
    short_version_string = "123.4",
    visibility = ["//examples/multiplatform:__subpackages__"],
)

ios_application(
    name = "iOSApp",
    app_icons = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
    bundle_id = "io.buildbuddy.example",
    bundle_name = "iOSApp",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    provisioning_profile = select({
        ":device_build": ":xcode_managed_profile",
        "//conditions:default": None,
    }),
    resources = [":ResourceGroup"],
    version = ":Version",
    visibility = ["//visibility:public"],
    watch_application = "//examples/multiplatform/watchOSApp",
    deps = [":iOSApp.library"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: io.buildbuddy.example",
    tags = ["manual"],
    team_id = "V82V4GQZXM",
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
    name = "iOSApp.library",
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
