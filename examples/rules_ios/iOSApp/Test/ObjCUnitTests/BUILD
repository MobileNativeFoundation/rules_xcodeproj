load(
    "@build_bazel_rules_ios//rules:test.bzl",
    rules_ios_ios_unit_test = "ios_unit_test",
)
load(
    "@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl",
    "ios_test_runner",
)
load(
    "//iOSApp/Test/ObjCUnitTests:macros.bzl",
    "rules_ios_unit_test_macro",
)

rules_ios_ios_unit_test(
    name = "iOSAppObjCUnitTests",
    srcs = glob(["**/*.m"]),
    bundle_id = "rules-xcodeproj.example.objctests",
    bundle_name = "iOS_App_ObjC_UnitTests",
    minimum_os_version = "15.0",
    module_name = "iOSAppObjCUnitTests",
    tags = ["manual"],
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [
        "//iOSApp/Source:iOSApp.library",
        "//iOSApp/Source/Utils",
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

rules_ios_ios_unit_test(
    name = "iOSAppObjCUnitTestSuite",
    srcs = glob(["**/*.m"]),
    bundle_id = "rules-xcodeproj.example.objctests",
    minimum_os_version = "15.0",
    module_name = "iOSAppObjCUnitTestSuite",
    runners = [
        ":iPhone-13-Pro__16.2",
        ":iPad-Air-4th-gen__16.2",
    ],
    tags = ["manual"],
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [
        "//iOSApp/Source:iOSApp.library",
        "//iOSApp/Source/Utils",
    ],
)

rules_ios_unit_test_macro(
    name = "macro",
)
