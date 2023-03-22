load("@build_bazel_rules_apple//apple:ios.bzl", "ios_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

ios_ui_test(
    name = "iOSAppUITests",
    bundle_id = "rules-xcodeproj.example.uitests",
    minimum_os_version = "15.0",
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":iOSAppUITests.library"],
)

swift_library(
    name = "iOSAppUITests.library",
    testonly = True,
    srcs = [":Sources"],
    module_name = "iOSAppUITests",
    tags = ["manual"],
    deps = ["@examples_ios_app_external//:ExternalResources"],
)

filegroup(
    name = "Sources",
    srcs = glob(["**/*.swift"]),
)
