load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_command_line_application",
)
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)

# This target exists to keep configurations the same between the generator
# and the tests, which makes the Xcode development experience better. If we used
# `swift_binary` or `apple_universal_binary` in `xcodeproj`, then the
# `macos_unit_test` transition (which is used to be able to set a minimum os
# version on the tests) will create slightly different configurations for our
# `swift_library`s. Maybe https://github.com/bazelbuild/bazel/issues/6526 will
# fix that for us.
macos_command_line_application(
    name = "calculate_output_groups",
    minimum_os_version = "13.0",
    visibility = ["//visibility:public"],
    deps = [":calculate_output_groups.library"],
)

swift_library(
    name = "calculate_output_groups.library",
    srcs = glob(["*.swift"]),
    module_name = "calculate_output_groups",
    deps = [
        "//tools/lib/ToolCommon",
        "@com_github_apple_swift_argument_parser//:ArgumentParser",
        "@com_github_michaeleisel_zippyjson//:ZippyJSON",
    ],
)

swift_binary(
    name = "calculate_output_groups_binary",
    deps = [":calculate_output_groups.library"],
)

apple_universal_binary(
    name = "universal_calculate_output_groups",
    binary = ":calculate_output_groups_binary",
    forced_cpus = [
        "x86_64",
        "arm64",
    ],
    minimum_os_version = "13.0",
    platform_type = "macos",
    visibility = ["//visibility:public"],
)

# Release

filegroup(
    name = "release_files",
    srcs = [
        "BUILD.release.bazel",
        ":universal_calculate_output_groups",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)
