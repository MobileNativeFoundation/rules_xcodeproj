load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

watchos_ui_test(
    name = "UITests",
    minimum_os_version = "7.0",
    tags = ["manual"],
    test_host = "//examples/multiplatform/watchOSApp",
    visibility = ["//visibility:public"],
    deps = [":UITests.library"],
)

swift_library(
    name = "UITests.library",
    testonly = True,
    srcs = [":Sources"],
    module_name = "UITestsLibrary",
    tags = ["manual"],
)

filegroup(
    name = "Sources",
    srcs = glob(["**/*.swift"]),
)
