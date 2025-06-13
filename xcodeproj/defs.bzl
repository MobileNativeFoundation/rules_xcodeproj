"""Public rules, macros, and libraries."""
# TODO: Remove this file in rules_xcodeproj 4.0

load(
    ":automatic_target_info.bzl",
    _XcodeProjAutomaticTargetProcessingInfo = "XcodeProjAutomaticTargetProcessingInfo",
)
load(":project_options.bzl", _project_options = "project_options")
load(
    ":top_level_target.bzl",
    _top_level_target = "top_level_target",
    _top_level_targets = "top_level_targets",
)
load(
    ":xcode_provisioning_profile.bzl",
    _xcode_provisioning_profile = "xcode_provisioning_profile",
)
load(":xcodeproj.bzl", _xcodeproj = "xcodeproj")
load(":xcodeprojinfo.bzl", _XcodeProjInfo = "XcodeProjInfo")
load(":xcschemes.bzl", _xcschemes = "xcschemes")

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
xcschemes = _xcschemes
