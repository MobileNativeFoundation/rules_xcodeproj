load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_command_line_application",
    "macos_unit_test",
)
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)

exports_files(["README.md"])

# Generator

swift_library(
    name = "target_build_settings.library",
    srcs = glob(["src/**/*.swift"]),
    module_name = "target_build_settings",
    deps = [
        "//tools/generators/lib/PBXProj",
        "//tools/lib/ToolCommon",
        "@com_github_apple_swift_collections//:OrderedCollections",
    ],
)

# This target exists to keep configurations the same between the generator
# and the tests, which makes the Xcode development experience better. If we used
# `swift_binary` or `apple_universal_binary` in `xcodeproj`, then the
# `macos_unit_test` transition (which is used to be able to set a minimum os
# version on the tests) will create slightly different configurations for our
# `swift_library`s. Maybe https://github.com/bazelbuild/bazel/issues/6526 will
# fix that for us.
macos_command_line_application(
    name = "target_build_settings",
    minimum_os_version = "13.0",
    visibility = ["//visibility:public"],
    deps = [":target_build_settings.library"],
)

swift_binary(
    name = "target_build_settings_binary",
    deps = [":target_build_settings.library"],
)

apple_universal_binary(
    name = "universal_target_build_settings",
    binary = ":target_build_settings_binary",
    forced_cpus = [
        "x86_64",
        "arm64",
    ],
    minimum_os_version = "13.0",
    platform_type = "macos",
    visibility = ["//visibility:public"],
)

# Tests

swift_library(
    name = "target_build_settings_tests.library",
    testonly = True,
    srcs = glob(["test/**/*.swift"]),
    module_name = "target_build_settings_tests",
    deps = [
        ":target_build_settings.library",
        "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
    ],
)

macos_unit_test(
    name = "target_build_settings_tests",
    minimum_os_version = "13.0",
    visibility = [
        "//test:__subpackages__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [
        ":target_build_settings_tests.library",
    ],
)

# Release

filegroup(
    name = "release_files",
    srcs = [
        "BUILD.release.bazel",
        ":universal_target_build_settings",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)
