load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")
load(
    ":xcodeproj_targets.bzl",
    "SCHEME_AUTOGENERATION_MODE",
    "XCODEPROJ_TARGETS",
    "get_xcode_schemes",
)

xcodeproj(
    name = "xcodeproj",
    build_mode = "bazel",
    project_name = "Sanitizers",
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    schemes = get_xcode_schemes(),
    tags = ["manual"],
    top_level_targets = XCODEPROJ_TARGETS,
)
