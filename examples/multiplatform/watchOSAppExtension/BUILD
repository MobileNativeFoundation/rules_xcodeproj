load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_extension")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

watchos_extension(
    name = "watchOSAppExtension",
    bundle_id = "io.buildbuddy.example.watch.extension",
    infoplists = [":Info.plist"],
    minimum_os_version = "7.0",
    resources = [":ResourceGroup"],
    version = "//examples/multiplatform/iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":watchOSAppExtension.library"],
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(["Assets.xcassets/**"]),
)

swift_library(
    name = "watchOSAppExtension.library",
    srcs = glob(["**/*.swift"]),
    data = select({
        ":release_build": [],
        "//conditions:default": [":PreviewContent"],
    }),
    module_name = "watchOSAppExtension",
    tags = ["manual"],
    visibility = ["//examples/multiplatform:__subpackages__"],
    deps = [
        "//examples/multiplatform/Lib",
    ],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)
