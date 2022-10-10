load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

ios_unit_test(
    name = "iOSAppSwiftUnitTests",
    bundle_id = "io.buildbuddy.example.tests",
    minimum_os_version = "15.0",
    resources = ["//iOSApp/Resources/ExampleResources:exported_resources"],
    test_host = "//iOSApp",
    visibility = ["//visibility:public"],
    env = {
        "IOSAPPSWIFTUNITTESTS": "CUSTOM_ENV_VAR"
    },
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
