load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

watchos_unit_test(
    name = "ExampleWatchKitAppTests",
    minimum_os_version = "7.0",
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = [":ExampleWatchKitAppTests.library"],
)

swift_library(
    name = "ExampleWatchKitAppTests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "ExampleWatchKitAppTests",
    tags = ["manual"],
    deps = [
        "//examples/watchos_app/ExampleWatchKitExtension:ExampleWatchKitExtension.library",
    ],
)
