"""Public rules, macros, and libraries."""

load(
    "//xcodeproj/internal:providers.bzl",
    _XcodeProjAutomaticTargetProcessingInfo = "XcodeProjAutomaticTargetProcessingInfo",
)
load("//xcodeproj/internal:xcode_schemes.bzl", _xcode_schemes = "xcode_schemes")
load("//xcodeproj/internal:xcodeproj_macro.bzl", _xcodeproj = "xcodeproj")

# Re-exporting providers
XcodeProjAutomaticTargetProcessingInfo = _XcodeProjAutomaticTargetProcessingInfo

# Re-exporting rules
xcodeproj = _xcodeproj

# Re-exporting APIs
xcode_schemes = _xcode_schemes
