load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

watchos_ui_test(
    name = "ExampleWatchKitAppUITests",
    minimum_os_version = "7.0",
    tags = ["manual"],
    test_host = "//examples/watchos_app/ExampleWatchKitApp",
    visibility = ["//visibility:public"],
    deps = [":ExampleWatchKitAppUITests.library"],
)

swift_library(
    name = "ExampleWatchKitAppUITests.library",
    testonly = True,
    srcs = [":Sources"],
    module_name = "ExampleUITests",
    tags = ["manual"],
)

filegroup(
    name = "Sources",
    srcs = glob(["**/*.swift"]),
)
