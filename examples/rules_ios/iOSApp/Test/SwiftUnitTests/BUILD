load("@build_bazel_rules_ios//rules:test.bzl", rules_ios_ios_unit_test = "ios_unit_test")

rules_ios_ios_unit_test(
    name = "iOSAppSwiftUnitTests",
    srcs = glob(["**/*.swift"]),
    args = ["--command_line_args=-AppleLanguages,(en-GB)"],
    bundle_id = "rules-xcodeproj.example.tests",
    minimum_os_version = "15.0",
    module_name = "iOSAppSwiftUnitTests",
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [
        "//iOSApp/Source:iOSApp.library",
        "//iOSApp/Source/Utils",
    ],
)
