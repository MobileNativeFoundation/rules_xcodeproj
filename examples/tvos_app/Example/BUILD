load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "Example.library",
    srcs = glob(["**/*.swift"]),
    module_name = "Example",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

tvos_application(
    name = "Example",
    bundle_id = "io.buildbuddy.example",
    bundle_name = "Example",
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    visibility = ["//visibility:public"],
    deps = [":Example.library"],
)
