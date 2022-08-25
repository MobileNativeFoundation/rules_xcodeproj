"""Public rules, macros, and libraries."""

# Re-export original rules rather than their wrapper macros
# so that stardoc documents the rule attributes, not an opaque
# **kwargs argument
load(
    "//xcodeproj/internal:providers.bzl",
    _XcodeProjAutomaticTargetProcessingInfo = "XcodeProjAutomaticTargetProcessingInfo",
)
load("//xcodeproj/internal:xcode_schemes.bzl", _xcode_schemes = "xcode_schemes")
load(
    "//xcodeproj/internal:xcodeproj_macro.bzl",
    _top_level_target = "top_level_target",
    _xcodeproj = "xcodeproj",
)

top_level_target = _top_level_target
XcodeProjAutomaticTargetProcessingInfo = _XcodeProjAutomaticTargetProcessingInfo
xcodeproj = _xcodeproj
xcode_schemes = _xcode_schemes
