load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

tvos_application(
    name = "tvOSApp",
    bundle_id = "io.buildbuddy.example",
    bundle_name = "tvOSApp",
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    resources = [":ResourceGroup"],
    visibility = ["//visibility:public"],
    deps = [":tvOSApp.library"],
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
