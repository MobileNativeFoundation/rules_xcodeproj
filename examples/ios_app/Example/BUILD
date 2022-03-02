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
    deps = [":Example.library"],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "Example.library",
    module_name = "Example",
    data = glob(["Assets.xcassets/**"]) + select({
        ":release_build": [],
        "//conditions:default": glob(["Preview Content/**"]),
    }),
    srcs = glob(["**/*.swift"]),
    deps = [
        "//examples/ios_app/Utils",
    ],
    visibility = ["//visibility:public"],
)
