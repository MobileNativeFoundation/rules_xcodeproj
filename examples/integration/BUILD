load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcodeproj",
)
load(
    ":xcodeproj_targets.bzl",
    "ASSOCIATED_EXTRA_FILES",
    "CONFIG",
    "EXTRA_FILES",
    "UNFOCUSED_TARGETS",
    "XCODEPROJ_TARGETS",
    "get_xcode_schemes",
)

exports_files(["README.md"])

xcodeproj(
    name = "xcodeproj",
    associated_extra_files = ASSOCIATED_EXTRA_FILES,
    build_mode = "xcode",
    config = CONFIG,
    extra_files = EXTRA_FILES,
    project_name = "Integration",
    scheme_autogeneration_mode = "all",
    schemes = get_xcode_schemes(),
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
    unfocused_targets = UNFOCUSED_TARGETS,
)
