"""Public rules, macros, and libraries."""

load(
    "//xcodeproj/internal:project_options.bzl",
    _project_options = "project_options",
)
load(
    "//xcodeproj/internal:providers.bzl",
    _XcodeProjAutomaticTargetProcessingInfo = "XcodeProjAutomaticTargetProcessingInfo",
    _XcodeProjInfo = "XcodeProjInfo",
)
load(
    "//xcodeproj/internal:top_level_target.bzl",
    _top_level_target = "top_level_target",
    _top_level_targets = "top_level_targets",
)
load(
    "//xcodeproj/internal:xcode_provisioning_profile.bzl",
    _xcode_provisioning_profile = "xcode_provisioning_profile",
)
load("//xcodeproj/internal:xcode_schemes.bzl", _xcode_schemes = "xcode_schemes")
load(
    "//xcodeproj/internal:xcodeproj_macro.bzl",
    _xcodeproj = "xcodeproj",
)
load("//xcodeproj/internal/xcschemes:xcschemes.bzl", _xcschemes = "xcschemes")

# Re-exporting providers
XcodeProjAutomaticTargetProcessingInfo = _XcodeProjAutomaticTargetProcessingInfo
XcodeProjInfo = _XcodeProjInfo

# Re-exporting rules
project_options = _project_options
top_level_target = _top_level_target
top_level_targets = _top_level_targets
xcodeproj = _xcodeproj
xcode_provisioning_profile = _xcode_provisioning_profile

# Re-exporting APIs
xcode_schemes = _xcode_schemes
xcschemes = _xcschemes
