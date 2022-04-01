load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

ios_unit_test(
    name = "ExampleTests",
    bundle_id = "io.buildbuddy.example.tests",
    minimum_os_version = "15.0",
    test_host = "//Example",
    visibility = ["//visibility:public"],
    deps = [":ExampleTests.library"],
)

swift_library(
    name = "ExampleTests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    data = ["//ExampleResources"],
    module_name = "ExampleTests",
    tags = ["manual"],
    deps = [
        "//Example:Example.library",
        "//TestingUtils",
        "//Utils",
    ],
)
