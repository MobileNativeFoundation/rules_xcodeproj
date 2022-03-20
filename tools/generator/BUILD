load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
    "swift_test",
)
load("//xcodeproj:xcodeproj.bzl", "xcodeproj")
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

swift_library(
    name = "generator.library",
    srcs = glob(["src/**/*.swift"]),
    module_name = "generator",
    deps = [
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

swift_library(
    name = "tests.library",
    testonly = True,
    srcs = glob(["test/**/*.swift"]),
    module_name = "tests",
    deps = [
        ":generator.library",
        "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
    ],
)

swift_test(
    name = "tests",
    visibility = ["//test:__subpackages__"],
    deps = [
        ":tests.library",
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
