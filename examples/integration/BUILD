load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "xcodeproj",
)
load(":xcodeproj_targets.bzl", "CONFIG", "XCODEPROJ_TARGETS")

xcodeproj(
    name = "xcodeproj",
    build_mode = "xcode",
    config = CONFIG,
    project_name = "Integration",
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)
