"""Exercise targets wrapped in macros"""

load(
    "@build_bazel_rules_ios//rules:test.bzl",
    rules_ios_ios_unit_test = "ios_unit_test",
)

def rules_ios_unit_test_macro(name):
    rules_ios_ios_unit_test(
        name = "iOSAppObjCUnitTests_{}".format(name),
        srcs = native.glob(["**/*.m"]),
        bundle_id = "rules-xcodeproj.example.objctests",
        bundle_name = "iOS_App_ObjC_UnitTests_{}".format(name),
        minimum_os_version = "15.0",
        module_name = "iOSAppObjCUnitTests_{}".format(name),
        tags = ["manual"],
        test_host = "//iOSApp",
        visibility = ["@rules_xcodeproj//xcodeproj:generated"],
        deps = [
            "//iOSApp/Source:iOSApp.library",
            "//iOSApp/Source/Utils",
        ],
    )
