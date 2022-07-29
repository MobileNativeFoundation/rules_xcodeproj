load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)
load("//xcodeproj:xcodeproj.bzl", "xcodeproj")
load(
    ":xcodeproj_targets.bzl",
    "SCHEME_AUTOGENERATION_MODE",
    "TOP_LEVEL_TARGETS",
    "UNFOCUSED_TARGETS",
    "get_xcode_schemes",
)

swift_library(
    name = "generator.library",
    srcs = glob(["src/**/*.swift"]),
    module_name = "generator",
    visibility = ["//tools/generator/test:__pkg__"],
    deps = [
        "@com_github_apple_swift_collections//:OrderedCollections",
        "@com_github_kylef_pathkit//:PathKit",
        "@com_github_tuist_xcodeproj//:XcodeProj",
    ],
)

swift_binary(
    name = "generator",
    visibility = ["//visibility:public"],
    deps = [
        ":generator.library",
    ],
)

xcodeproj(
    name = "xcodeproj",
    build_mode = "bazel",
    project_name = "generator",
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    schemes = get_xcode_schemes(),
    tags = ["manual"],
    top_level_targets = TOP_LEVEL_TARGETS,
    unfocused_targets = UNFOCUSED_TARGETS,
)

# Integration test related targets

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//:__subpackages__"],
)
