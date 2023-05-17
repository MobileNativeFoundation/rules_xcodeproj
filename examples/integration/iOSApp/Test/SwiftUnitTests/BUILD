load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_unit_test",
    "ios_unit_test_suite",
)
load(
    "@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl",
    "ios_test_runner",
)
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
    tags = ["manual"],
    test_host = "//iOSApp",
    visibility = [
        "//iOSApp:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
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

ios_unit_test_suite(
    name = "iOSAppSwiftUnitTestSuite",
    args = ["--command_line_args=-AppleLanguages,(en-GB)"],
    bundle_id = "rules-xcodeproj.example.tests",
    env = {
        "IOS_APP_UNIT_TESTS": "CUSTOM_ENV_VALUE",
    },
    minimum_os_version = "15.0",
    resources = ["//iOSApp/Resources/ExampleResources:exported_resources"],
    runners = [
        ":iPhone-13-Pro__16.2",
        ":iPad-Air-4th-gen__16.2",
    ],
    tags = ["manual"],
    test_host = "//iOSApp",
    visibility = [
        "//iOSApp:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [":iOSAppSwiftUnitTestSuite.library"],
)

swift_library(
    name = "iOSAppSwiftUnitTestSuite.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "iOSAppSwiftUnitTestSuite",
    tags = ["manual"],
    deps = [
        "//iOSApp/Source:iOSApp.library",
        "//iOSApp/Source/Utils",
        "//iOSApp/Test/TestingUtils",
    ],
)
