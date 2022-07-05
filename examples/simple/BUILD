load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("//xcodeproj:xcodeproj.bzl", "xcodeproj")
load(":xcodeproj_targets.bzl", "XCODEPROJ_TARGETS")

swift_library(
    name = "SwiftLib",
    srcs = glob(["*.swift"]),
    visibility = ["//visibility:public"],
)

xcodeproj(
    name = "xcodeproj",
    build_mode = "bazel",
    project_name = "Simple",
    tags = ["manual"],
    targets = XCODEPROJ_TARGETS,
)
