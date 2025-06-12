load("@rules_xcodeproj//xcodeproj:xcodeproj.bzl", "xcodeproj")
load(
    ":xcodeproj_targets.bzl",
    "SCHEME_AUTOGENERATION_MODE",
    "XCODEPROJ_TARGETS",
)

xcodeproj(
    name = "xcodeproj",
    project_name = "Sanitizers",
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)
