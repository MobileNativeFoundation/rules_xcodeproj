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
load("//xcodeproj:defs.bzl", "xcodeproj", "xcschemes")

# This target exists to keep configurations the same between the generator
# and the tests, which makes the Xcode development experience better. If we used
# `swift_binary` or `apple_universal_binary` in `xcodeproj`, then the
# `macos_unit_test` transition (which is used to be able to set a minimum os
# version on the tests) will create slightly different configurations for our
# `swift_library`s. Maybe https://github.com/bazelbuild/bazel/issues/6526 will
# fix that for us.
macos_command_line_application(
    name = "xcode_to_bazel",
    minimum_os_version = "12.0",
    visibility = ["//visibility:public"],
    deps = [":xcode_to_bazel.library"],
)

swift_library(
    name = "xcode_to_bazel.library",
    srcs = glob(["*.swift"]),
    module_name = "xcode_to_bazel",
    deps = [
        "@com_github_tuist_xcodeproj//:XcodeProj",
        "//tools/lib/ToolCommon",
    ],
)

swift_binary(
    name = "xcode_to_bazel_binary",
    deps = [":xcode_to_bazel.library"],
)

apple_universal_binary(
    name = "universal_xcode_to_bazel",
    binary = ":xcode_to_bazel_binary",
    forced_cpus = [
        "x86_64",
        "arm64",
    ],
    minimum_os_version = "12.0",
    platform_type = "macos",
    visibility = ["//visibility:public"],
)


xcodeproj(
    name = "xcodeproj",
    generation_mode = "incremental",
    project_name = "xcode_to_bazel",
    scheme_autogeneration_mode = "none",
    top_level_targets = [
        ":xcode_to_bazel",
    ],
    xcschemes = [
        xcschemes.scheme(
            name = "xcode_to_bazel",
            run = xcschemes.run(
                launch_target = ":xcode_to_bazel",
                args = [
                    "/Users/brentley/Developer/mastodon-ios",
                    "Mastodon.xcodeproj",
                ],
            ),
        ),
    ],
)
