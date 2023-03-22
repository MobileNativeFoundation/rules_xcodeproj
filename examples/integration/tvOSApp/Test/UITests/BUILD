load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

tvos_ui_test(
    name = "tvOSAppUITests",
    bundle_id = "rules-xcodeproj.example.uitests",
    minimum_os_version = "15.0",
    # xctestrunner does not support tvOS. So, don't try to run this.
    tags = ["manual"],
    test_host = "//tvOSApp/Source:tvOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":tvOSAppUITests.library"],
)

swift_library(
    name = "tvOSAppUITests.library",
    testonly = True,
    srcs = [":Sources"],
    module_name = "tvOSAppUITests",
    tags = ["manual"],
)

filegroup(
    name = "Sources",
    srcs = glob(["*.swift"]),
)
