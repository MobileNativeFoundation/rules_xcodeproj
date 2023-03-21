load("@build_bazel_rules_apple//apple:macos.bzl", "macos_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

macos_ui_test(
    name = "macOSAppUITests",
    bundle_id = "rules-xcodeproj.macosapp.uitests",
    minimum_os_version = "12.0",
    # xctestrunner does not support macOS. So, don't try to run this.
    tags = ["manual"],
    test_host = "//macOSApp/Source:macOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":macOSAppUITests.library"],
)

swift_library(
    name = "macOSAppUITests.library",
    testonly = True,
    srcs = [":Sources"],
    module_name = "macOSAppUITests",
    tags = ["manual"],
)

filegroup(
    name = "Sources",
    srcs = glob(["*.swift"]),
)
