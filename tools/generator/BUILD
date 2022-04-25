load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)
load("//xcodeproj:xcodeproj.bzl", "xcodeproj")
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

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
    project_name = "generator",
    tags = ["manual"],
    targets = XCODEPROJ_TARGETS,
)

# Integration test related targets

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//:__subpackages__"],
)
