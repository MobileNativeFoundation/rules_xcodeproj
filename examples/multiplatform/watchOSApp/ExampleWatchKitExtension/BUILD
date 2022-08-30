load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_extension")
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
        "cpu": "watchos_arm64_32",
    },
)

watchos_extension(
    name = "ExampleWatchKitExtension",
    bundle_id = "io.buildbuddy.example.watch.extension",
    infoplists = [":Info.plist"],
    minimum_os_version = "7.0",
    resources = [":ResourceGroup"],
    provisioning_profile = select({
        ":device_build": ":xcode_profile",
        "//conditions:default": None,
    }),
    version = "//examples/multiplatform/watchOSApp/Example:Version",
    visibility = ["//visibility:public"],
    deps = [":ExampleWatchKitExtension.library"],
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(["Assets.xcassets/**"]),
)

swift_library(
    name = "ExampleWatchKitExtension.library",
    srcs = glob(["**/*.swift"]),
    data = select({
        ":release_build": [],
        "//conditions:default": [":PreviewContent"],
    }),
    module_name = "ExampleWatchKitExtension",
    tags = ["manual"],
    visibility = ["//examples/multiplatform/watchOSApp:__subpackages__"],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)
