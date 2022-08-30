load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

watchos_unit_test(
    name = "UnitTests",
    minimum_os_version = "7.0",
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = [":UnitTests.library"],
)

swift_library(
    name = "UnitTests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "UnitTestsLibrary",
    tags = ["manual"],
    deps = [
        "//examples/multiplatform/watchOSAppExtension",
    ],
)
