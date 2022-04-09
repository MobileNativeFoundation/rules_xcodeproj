load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

tvos_unit_test(
    name = "ExampleTests",
    bundle_id = "io.buildbuddy.example.tests",
    minimum_os_version = "15.0",
    # xctestrunner does not support tvOS. So, don't try to run this.
    tags = ["manual"],
    test_host = "//examples/tvos_app/Example",
    visibility = ["//visibility:public"],
    deps = [":ExampleTests.library"],
)

swift_library(
    name = "ExampleTests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "ExampleTests",
    tags = ["manual"],
    deps = [
        "//examples/tvos_app/Example:Example.library",
    ],
)
