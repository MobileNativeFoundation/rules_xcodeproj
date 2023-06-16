load(
    "@build_bazel_rules_ios//rules:test.bzl",
    rules_ios_ios_ui_test = "ios_ui_test",
)
load(
    "@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl",
    "ios_test_runner",
)
load(
    "//iOSApp/Test/UITests:macros.bzl",
    "rules_ios_ui_test_macro",
)

rules_ios_ios_ui_test(
    name = "iOSAppUITests",
    srcs = glob(["**/*.swift"]),
    bundle_id = "rules-xcodeproj.example.uitests",
    minimum_os_version = "15.0",
    module_name = "iOSAppUITests",
    tags = ["manual"],
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
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

rules_ios_ios_ui_test(
    name = "iOSAppUITestSuite",
    srcs = glob(["**/*.swift"]),
    bundle_id = "rules-xcodeproj.example.uitests",
    minimum_os_version = "15.0",
    module_name = "iOSAppUITestSuite",
    runners = [
        ":iPhone-13-Pro__16.2",
        ":iPad-Air-4th-gen__16.2",
    ],
    tags = ["manual"],
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)

rules_ios_ui_test_macro(
    name = "macro",
)
