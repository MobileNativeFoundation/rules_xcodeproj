load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "tests.library",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    module_name = "tests",
    deps = [
        "//tools/generator:generator.library",
        "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
    ],
)

macos_unit_test(
    name = "tests",
    minimum_os_version = "12.0",
    visibility = [
        "//.rules_xcodeproj:__subpackages__",
        "//test:__subpackages__",
    ],
    deps = [
        ":tests.library",
    ],
)
