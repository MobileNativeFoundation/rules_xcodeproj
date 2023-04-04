load("@build_bazel_rules_ios//rules:test.bzl", rules_ios_ios_ui_test = "ios_ui_test")

rules_ios_ios_ui_test(
    name = "iOSAppUITests",
    srcs = glob(["**/*.swift"]),
    bundle_id = "rules-xcodeproj.example.uitests",
    minimum_os_version = "15.0",
    module_name = "iOSAppUITests",
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)
