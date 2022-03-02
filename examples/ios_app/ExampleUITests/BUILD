load("@build_bazel_rules_apple//apple:ios.bzl", "ios_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

ios_ui_test(
    name = "ExampleUITests",
    bundle_id = "io.buildbuddy.example.uitests",
    minimum_os_version = "15.0",
    test_host = "//examples/ios_app/Example",
    deps = [":ExampleUITests.library"],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "ExampleUITests.library",
    module_name = "ExampleUITests",
    testonly = True,
    srcs = [":Sources"],
)

filegroup(
    name = "Sources",
    srcs = glob(["**/*.swift"]),
)
