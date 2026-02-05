load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_unit_test",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

ios_unit_test(
    name = "MixedLibTests",
    bundle_id = "rules-xcodeproj.mixedlib.tests",
    minimum_os_version = "16.0",
    tags = ["manual"],
    visibility = [
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [":MixedLibTests.library"],
)

swift_library(
    name = "MixedLibTests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "MixedLibTests",
    tags = ["manual"],
    deps = [
        "//MixedLib",
    ],
)
