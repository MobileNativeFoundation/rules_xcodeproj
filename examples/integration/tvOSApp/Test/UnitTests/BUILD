load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

tvos_unit_test(
    name = "tvOSAppUnitTests",
    bundle_id = "rules-xcodeproj.example.tests",
    minimum_os_version = "15.0",
    # xctestrunner does not support tvOS. So, don't try to run this.
    tags = ["manual"],
    test_host = "//tvOSApp/Source:tvOSApp",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [":tvOSAppUnitTests.library"],
)

swift_library(
    name = "tvOSAppUnitTests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "tvOSAppUnitTests",
    tags = ["manual"],
    deps = [
        "//tvOSApp/Source:tvOSApp.library",
    ],
)
