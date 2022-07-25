load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)
load("//xcodeproj:xcodeproj.bzl", "xcodeproj")
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

swift_library(
    name = "bep_parser.library",
    srcs = glob(["src/**/*.swift"]),
    module_name = "bep_parser",
    visibility = ["//tools/bep_parser/test:__pkg__"],
    deps = [
        "//tools/bep_parser/bep",
        # TODO: Confirm it still works without this
        "@com_github_apple_swift_protobuf//:SwiftProtobuf",
    ],
)

swift_binary(
    name = "bep_parser",
    visibility = ["//visibility:public"],
    deps = [
        ":bep_parser.library",
    ],
)

xcodeproj(
    name = "xcodeproj",
    project_name = "bep_parser",
    tags = ["manual"],
    targets = XCODEPROJ_TARGETS,
)

# Integration test related targets

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//:__subpackages__"],
)
