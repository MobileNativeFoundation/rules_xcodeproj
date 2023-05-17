load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_unit_test",
    "ios_unit_test_suite",
)
load(
    "@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl",
    "ios_test_runner",
)

ios_unit_test(
    name = "iOSAppObjCUnitTests",
    bundle_id = "rules-xcodeproj.example.objctests",
    env = {
        "IOS_APP_UNIT_TESTS": "CUSTOM_ENV_VALUE",
    },
    minimum_os_version = "15.0",
    tags = ["manual"],
    test_host = "//iOSApp",
    visibility = [
        "//iOSApp:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [":iOSAppObjCUnitTests.library"],
)

objc_library(
    name = "iOSAppObjCUnitTests.library",
    testonly = True,
    srcs = glob(["**/*.m"]),
    data = [
        "//iOSApp/Resources/OnlyStructuredResources",
        "@examples_ios_app_external//:ExternalImportedBundle",
    ],
    enable_modules = True,
    includes = ["../TestingUtils"],
    module_name = "iOSAppObjCUnitTests",
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
    name = "iOSAppObjCUnitTestSuite",
    bundle_id = "rules-xcodeproj.example.objctests",
    env = {
        "IOS_APP_UNIT_TESTS": "CUSTOM_ENV_VALUE",
    },
    minimum_os_version = "15.0",
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
    deps = [":iOSAppObjCUnitTestSuite.library"],
)

objc_library(
    name = "iOSAppObjCUnitTestSuite.library",
    testonly = True,
    srcs = glob(["**/*.m"]),
    data = [
        "//iOSApp/Resources/OnlyStructuredResources",
        "@examples_ios_app_external//:ExternalImportedBundle",
    ],
    enable_modules = True,
    includes = ["../TestingUtils"],
    module_name = "iOSAppObjCUnitTestsSuite",
    tags = ["manual"],
    deps = [
        "//iOSApp/Source:iOSApp.library",
        "//iOSApp/Source/Utils",
        "//iOSApp/Test/TestingUtils",
    ],
)
