load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcodeproj",
)
load(
    "//:xcodeproj_targets.bzl",
    "XCODEPROJ_TARGETS",
)

xcodeproj(
    name = "xcodeproj",
    build_mode = "bazel",
    project_name = "Sanitizers",
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)
