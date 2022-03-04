load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
    "swift_test",
)
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "xcodeproj",
)
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

swift_library(
    name = "generator.library",
    module_name = "generator",
    srcs = glob(["src/**/*.swift"]),
    deps = [
        "@com_github_tuist_xcodeproj//:XcodeProj",
        "@com_github_kylef_pathkit//:PathKit",
    ],
)

swift_binary(
    name = "generator",
    deps = [
        ":generator.library",
    ],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "tests.library",
    module_name = "tests",
    srcs = glob(["test/**/*.swift"]),
    testonly = True,
    deps = [
        "@com_github_pointfreeco_swift_custom_dump//:CustomDump",
        ":generator.library",
    ],
)

swift_test(
    name = "tests",
    deps = [
        ":tests.library",
    ],
    visibility = ["//test:__subpackages__"],
)

xcodeproj(
    name = "xcodeproj",
    project_name = "generator",
    targets = XCODEPROJ_TARGETS,
    tags = ["manual"],
)
