load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

ios_unit_test(
    name = "iOSAppSwiftUnitTests",
    args = ["--command_line_args=-AppleLanguages,(en-GB)"],
    bundle_id = "rules-xcodeproj.example.tests",
    env = {
        "IOS_APP_UNIT_TESTS": "CUSTOM_ENV_VALUE",
    },
    minimum_os_version = "15.0",
    resources = ["//iOSApp/Resources/ExampleResources:exported_resources"],
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":iOSAppSwiftUnitTests.library"],
)

swift_library(
    name = "iOSAppSwiftUnitTests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "iOSAppSwiftUnitTests",
    tags = ["manual"],
    deps = [
        "//iOSApp/Source:iOSApp.library",
        "//iOSApp/Source/Utils",
        "//iOSApp/Test/TestingUtils",
    ],
)
