load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_ui_test",
    "ios_ui_test_suite",
)
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)
load(
    "@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl",
    "ios_test_runner",
)

ios_ui_test(
    name = "iOSAppUITests",
    bundle_id = "rules-xcodeproj.example.uitests",
    minimum_os_version = "15.0",
    tags = ["manual"],
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

ios_test_runner(
    name = "iPhone-13-Pro__16.2",
    device_type = "iPhone 13 Pro",
    os_version = "16.2",
)

ios_test_runner(
    name = "iPad-Air-4th-gen__16.2",
    device_type = "iPad Air (4th generation)",
    os_version = "16.2",
)

ios_ui_test_suite(
    name = "iOSAppUITestSuite",
    bundle_id = "rules-xcodeproj.example.uitests",
    minimum_os_version = "15.0",
    runners = [
        ":iPhone-13-Pro__16.2",
        ":iPad-Air-4th-gen__16.2",
    ],
    tags = ["manual"],
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":iOSAppUITestSuite.library"],
)

swift_library(
    name = "iOSAppUITestSuite.library",
    testonly = True,
    srcs = [":Sources"],
    module_name = "iOSAppUITestSuite",
    tags = ["manual"],
    deps = ["@examples_ios_app_external//:ExternalResources"],
)
