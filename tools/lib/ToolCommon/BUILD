load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# Library

swift_library(
    name = "ToolCommon",
    srcs = glob(["src/**/*.swift"]),
    module_name = "ToolCommon",
    visibility = ["//tools:__subpackages__"],
    deps = [
        "@com_github_apple_swift_argument_parser//:ArgumentParser",
    ],
)

# Tests

swift_library(
    name = "ToolCommonTests.library",
    testonly = True,
    srcs = glob(["test/**/*.swift"]),
    module_name = "ToolCommonTests",
    deps = [
        ":ToolCommon",
        "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
    ],
)

macos_unit_test(
    name = "ToolCommonTests",
    minimum_os_version = "13.0",
    visibility = [
        "//test:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [
        ":ToolCommonTests.library",
    ],
)
