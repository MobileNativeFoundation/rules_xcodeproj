load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")
load(
    ":xcodeproj_targets.bzl",
    "SCHEME_AUTOGENERATION_MODE",
    "XCODEPROJ_TARGETS",
    "XCSCHEMES",
    "get_extra_files",
)

exports_files(["README.md"])

xcodeproj(
    name = "xcodeproj",
    extra_files = get_extra_files(),
    project_name = "rules_ios",
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
    xcschemes = XCSCHEMES,
)
