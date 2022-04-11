load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

tvos_ui_test(
    name = "ExampleUITests",
    bundle_id = "io.buildbuddy.example.uitests",
    minimum_os_version = "15.0",
    # xctestrunner does not support tvOS. So, don't try to run this.
    tags = ["manual"],
    test_host = "//examples/tvos_app/Example",
    visibility = ["//visibility:public"],
    deps = [":ExampleUITests.library"],
)

swift_library(
    name = "ExampleUITests.library",
    testonly = True,
    srcs = [":Sources"],
    module_name = "ExampleUITests",
    tags = ["manual"],
)

filegroup(
    name = "Sources",
    srcs = glob(["**/*.swift"]),
)
