load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")

ios_unit_test(
    name = "iOSAppObjCUnitTests",
    bundle_id = "io.buildbuddy.example.objctests",
    env = {
        "IOSAPPOBJCUNITTESTS": "CUSTOM_ENV_VALUE",
    },
    minimum_os_version = "15.0",
    test_host = "//iOSApp",
    visibility = ["//visibility:public"],
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
    module_name = "iOSAppObjCUnitTests",
    tags = ["manual"],
    deps = [
        "//iOSApp/Source:iOSApp.library",
        "//iOSApp/Source/Utils",
        "//iOSApp/Test/TestingUtils",
    ],
)
