load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcodeproj",
)
load(
    ":xcodeproj_targets.bzl",
    "ASSOCIATED_EXTRA_FILES",
    "CONFIG",
    "EXTRA_FILES",
    "XCODEPROJ_TARGETS",
)

exports_files(["README.md"])

xcodeproj(
    name = "xcodeproj",
    associated_extra_files = ASSOCIATED_EXTRA_FILES,
    build_mode = "xcode",
    config = CONFIG,
    extra_files = EXTRA_FILES,
    project_name = "Integration",
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)
