load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcodeproj",
)
load(
    "//:xcodeproj_targets.bzl",
    "POST_BUILD",
    "PRE_BUILD",
    "XCODEPROJ_TARGETS",
)

swift_binary(
    name = "SwiftBin",
    srcs = glob(["*.swift"]),
    defines = ["HI"],
    module_name = "SwiftBinModuleName",
    visibility = ["//visibility:public"],
)

xcodeproj(
    name = "xcodeproj",
    build_mode = "xcode",
    post_build = POST_BUILD,
    pre_build = PRE_BUILD,
    project_name = "Simple",
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)
