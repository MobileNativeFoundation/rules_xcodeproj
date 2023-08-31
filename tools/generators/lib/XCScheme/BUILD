load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# Library

swift_library(
    name = "XCScheme",
    srcs = glob(["src/**/*.swift"]),
    module_name = "XCScheme",
    visibility = ["//tools/generators:__subpackages__"],
    deps = [
        "//tools/generators/lib/PBXProj",
    ],
)

# Tests

swift_library(
    name = "XCSchemeTests.library",
    testonly = True,
    srcs = glob(["test/**/*.swift"]),
    module_name = "XCSchemeTests",
    deps = [
        ":XCScheme",
        "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
    ],
)

macos_unit_test(
    name = "XCSchemeTests",
    minimum_os_version = "13.0",
    visibility = [
        "//test:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [
        ":XCSchemeTests.library",
    ],
)
