load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# Library

swift_library(
    name = "PBXProj",
    srcs = glob(["src/**/*.swift"]),
    module_name = "PBXProj",
    visibility = ["//tools/generators:__subpackages__"],
    deps = [
        "//tools/generators/lib/GeneratorCommon",
        "@com_github_apple_swift_argument_parser//:ArgumentParser",
    ],
)

# Tests

swift_library(
    name = "PBXProjTests.library",
    testonly = True,
    srcs = glob(["test/**/*.swift"]),
    module_name = "PBXProjTests",
    deps = [
        ":PBXProj",
        "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
    ],
)

macos_unit_test(
    name = "PBXProjTests",
    minimum_os_version = "13.0",
    visibility = [
        "//test:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [
        ":PBXProjTests.library",
    ],
)
