load(
    "//tools/generator:xcodeproj_targets.bzl",
    "PRE_BUILD",
    "SCHEME_AUTOGENERATION_MODE",
    "TOP_LEVEL_TARGETS",
    "UNFOCUSED_TARGETS",
    "get_xcode_schemes",
)
load("//xcodeproj:testing.bzl", "xcodeproj_fixture")

xcodeproj_fixture(
    pre_build = PRE_BUILD,
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    schemes = get_xcode_schemes(),
    top_level_targets = TOP_LEVEL_TARGETS,
    unfocused_targets = UNFOCUSED_TARGETS,
)
