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
load("//xcodeproj:defs.bzl", "xcodeproj")
load(
    ":xcodeproj_targets.bzl",
    "SCHEME_AUTOGENERATION_MODE",
    "TOP_LEVEL_TARGETS",
    "UNFOCUSED_TARGETS",
    "XCODE_CONFIGURATIONS",
    "XCSCHEMES",
    "get_xcode_schemes",
)

swift_library(
    name = "generator.library",
    srcs = glob(["src/**/*.swift"]),
    module_name = "generator",
    visibility = ["//tools/generators/legacy/test:__pkg__"],
    deps = [
        "//tools/lib/ToolCommon",
        "@com_github_apple_swift_collections//:OrderedCollections",
        "@com_github_kylef_pathkit//:PathKit",
        "@com_github_michaeleisel_zippyjson//:ZippyJSON",
        "@com_github_tuist_xcodeproj//:XcodeProj",
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
    name = "generator",
    minimum_os_version = "12.0",
    visibility = ["//visibility:public"],
    deps = [":generator.library"],
)

swift_binary(
    name = "generator_binary",
    deps = [":generator.library"],
)

apple_universal_binary(
    name = "universal_generator",
    binary = ":generator_binary",
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
    project_name = "generator",
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    schemes = get_xcode_schemes(),
    tags = ["manual"],
    top_level_targets = TOP_LEVEL_TARGETS,
    unfocused_targets = UNFOCUSED_TARGETS,
    xcode_configurations = XCODE_CONFIGURATIONS,
)

xcodeproj(
    name = "xcodeproj_cat",
    generation_mode = "incremental",
    project_name = "generator_cat",
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    schemes = get_xcode_schemes(),
    tags = ["manual"],
    top_level_targets = TOP_LEVEL_TARGETS,
    unfocused_targets = UNFOCUSED_TARGETS,
    xcode_configurations = XCODE_CONFIGURATIONS,
    xcschemes = XCSCHEMES,
)

# Release

filegroup(
    name = "release_files",
    srcs = [
        "BUILD.release.bazel",
        ":universal_generator",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)
