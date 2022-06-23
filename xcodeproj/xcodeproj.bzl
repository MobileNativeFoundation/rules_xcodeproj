"""Public rules, macros, and libraries."""

load(
    "//xcodeproj/internal:providers.bzl",
    _XcodeProjAutomaticTargetProcessingInfo = "XcodeProjAutomaticTargetProcessingInfo",
)
load("//xcodeproj/internal:xcodeproj.bzl", _xcodeproj = "xcodeproj")

# Re-exporting providers
XcodeProjAutomaticTargetProcessingInfo = _XcodeProjAutomaticTargetProcessingInfo

# Re-exporting rules
xcodeproj = _xcodeproj
