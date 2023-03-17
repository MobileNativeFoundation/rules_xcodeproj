load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

watchos_ui_test(
    name = "watchOSAppUITests",
    minimum_os_version = "7.0",
    tags = ["manual"],
    test_host = "//watchOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":watchOSAppUITests.library"],
)

swift_library(
    name = "watchOSAppUITests.library",
    testonly = True,
    srcs = [":Sources"],
    module_name = "watchOSAppUITestsLibrary",
    tags = ["manual"],
)

filegroup(
    name = "Sources",
    srcs = glob(["**/*.swift"]),
)
