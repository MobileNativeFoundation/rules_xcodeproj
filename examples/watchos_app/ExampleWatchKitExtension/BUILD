load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_apple//apple:versioning.bzl", "apple_bundle_version")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_extension")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

apple_bundle_version(
    name = "Version",
    build_version = "1.0",
    visibility = ["//examples/watchos_app:__subpackages__"],
)

watchos_extension(
    name = "ExampleWatchKitExtension",
    bundle_id = "io.buildbuddy.example.watch.extension",
    infoplists = [":Info.plist"],
    minimum_os_version = "7.0",
    resources = [":ResourceGroup"],
    version = ":Version",
    visibility = ["//visibility:public"],
    deps = [":ExampleWatchKitExtension.library"],
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
    visibility = ["//examples/watchos_app:__subpackages__"],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)
