load("@build_bazel_rules_ios//rules:test.bzl", rules_ios_ios_ui_test = "ios_ui_test")
load("@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl", "ios_test_runner")

rules_ios_ios_ui_test(
    name = "iOSAppUITests",
    srcs = glob(["**/*.swift"]),
    bundle_id = "rules-xcodeproj.example.uitests",
    minimum_os_version = "15.0",
    module_name = "iOSAppUITests",
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)

ios_test_runner(
    name = "iPhone-13-Pro__16.2",
    device_type = "iPhone 13 Pro",
    os_version = "16.2",
)

ios_test_runner(
    name = "iPad-Air-2__16.2",
    device_type = "iPad Air 2",
    os_version = "16.2",
)

rules_ios_ios_ui_test(
    name = "iOSAppUITestSuite",
    srcs = glob(["**/*.swift"]),
    bundle_id = "rules-xcodeproj.example.uitests",
    minimum_os_version = "15.0",
    module_name = "iOSAppUITestSuite",
    runners = [
        ":iPhone-13-Pro__16.2",
        ":iPad-Air-2__16.2",
    ],
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)
