load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

watchos_unit_test(
    name = "watchOSAppExtensionUnitTests",
    frameworks = ["//UI:UIFramework.watchOS"],
    minimum_os_version = "7.0",
    tags = ["manual"],
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":watchOSAppExtensionUnitTests.library"],
)

swift_library(
    name = "watchOSAppExtensionUnitTests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "watchOSAppExtensionUnitTestsLibrary",
    tags = ["manual"],
    deps = [
        "//UI",
    ],
)
