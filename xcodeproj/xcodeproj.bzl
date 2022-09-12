"""Public rules, macros, and libraries."""

load(
    "//xcodeproj/internal:top_level_target.bzl",
    _top_level_target = "top_level_target",
)
load(
    "//xcodeproj/internal:providers.bzl",
    _XcodeProjAutomaticTargetProcessingInfo = "XcodeProjAutomaticTargetProcessingInfo",
    _XcodeProjInfo = "XcodeProjInfo",
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

# Re-exporting providers
XcodeProjInfo = _XcodeProjInfo
XcodeProjAutomaticTargetProcessingInfo = _XcodeProjAutomaticTargetProcessingInfo

# Re-exporting rules
xcodeproj = _xcodeproj
xcode_provisioning_profile = _xcode_provisioning_profile
top_level_target = _top_level_target

# Re-exporting APIs
xcode_schemes = _xcode_schemes
