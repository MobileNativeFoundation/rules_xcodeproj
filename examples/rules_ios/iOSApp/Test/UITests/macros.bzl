"""Exercise targets wrapped in macros"""

load(
    "@build_bazel_rules_ios//rules:test.bzl",
    rules_ios_ios_ui_test = "ios_ui_test",
)

def rules_ios_ui_test_macro(name):
    rules_ios_ios_ui_test(
        name = "iOSAppUITests_{}".format(name),
        srcs = native.glob(["**/*.swift"]),
        bundle_id = "rules-xcodeproj.example.uitests",
        minimum_os_version = "15.0",
        module_name = "iOSAppUITests_{}".format(name),
        tags = ["manual"],
        test_host = "//iOSApp",
        visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    )
