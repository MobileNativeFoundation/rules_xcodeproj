load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

tvos_ui_test(
    name = "tvOSAppUITests",
    bundle_id = "io.buildbuddy.example.uitests",
    minimum_os_version = "15.0",
    # xctestrunner does not support tvOS. So, don't try to run this.
    tags = ["manual"],
    test_host = "//examples/integration/tvOSApp/Source:tvOSApp",
    visibility = ["//visibility:public"],
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
