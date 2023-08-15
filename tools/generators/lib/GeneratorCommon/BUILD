load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# Library

swift_library(
    name = "GeneratorCommon",
    srcs = glob(["src/**/*.swift"]),
    module_name = "GeneratorCommon",
    visibility = ["//tools:__subpackages__"],
    deps = [
        "@com_github_apple_swift_argument_parser//:ArgumentParser",
    ],
)

# Tests

swift_library(
    name = "GeneratorCommonTests.library",
    testonly = True,
    srcs = glob(["test/**/*.swift"]),
    module_name = "GeneratorCommonTests",
    deps = [
        ":GeneratorCommon",
        "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
    ],
)

macos_unit_test(
    name = "GeneratorCommonTests",
    minimum_os_version = "13.0",
    visibility = [
        "//test:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [
        ":GeneratorCommonTests.library",
    ],
)
