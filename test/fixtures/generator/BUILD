load(
    "//tools/generator:xcodeproj_targets.bzl",
    "SCHEME_AUTOGENERATION_MODE",
    "TOP_LEVEL_TARGETS",
    "UNFOCUSED_TARGETS",
    "XCODE_CONFIGURATIONS",
    "get_xcode_schemes",
)
load("//xcodeproj:testing.bzl", "xcodeproj_fixture")

xcodeproj_fixture(
    scheme_autogeneration_mode = SCHEME_AUTOGENERATION_MODE,
    schemes = get_xcode_schemes(),
    top_level_targets = TOP_LEVEL_TARGETS,
    unfocused_targets = UNFOCUSED_TARGETS,
    xcode_configurations = XCODE_CONFIGURATIONS,
)
