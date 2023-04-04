load(
    "@build_bazel_rules_ios//rules:test.bzl",
    rules_ios_ios_unit_test = "ios_unit_test",
)

rules_ios_ios_unit_test(
    name = "iOSAppObjCUnitTests",
    srcs = glob(["**/*.m"]),
    bundle_id = "rules-xcodeproj.example.objctests",
    minimum_os_version = "15.0",
    module_name = "iOSAppObjCUnitTests",
    test_host = "//iOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [
        "//iOSApp/Source:iOSApp.library",
        "//iOSApp/Source/Utils",
    ],
)
