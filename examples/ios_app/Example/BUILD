load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

ios_application(
    name = "Example",
    bundle_id = "io.buildbuddy.example",
    bundle_name = "Example",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "15.0",
    visibility = ["//visibility:public"],
    deps = [":Example.library"],
)

swift_library(
    name = "Example.library",
    srcs = glob(["**/*.swift"]),
    data = glob(["Assets.xcassets/**"]) + select({
        ":release_build": [],
        "//conditions:default": [":PreviewContent"],
    }),
    module_name = "Example",
    visibility = ["//visibility:public"],
    deps = [
        "//Utils",
    ],
)

filegroup(
    name = "PreviewContent",
    srcs = glob(["PreviewContent/**"]),
)
