"""Public rules, macros, and libraries."""

load(
    "//xcodeproj/internal:providers.bzl",
    _InputFileAttributesInfo = "InputFileAttributesInfo",
)
load("//xcodeproj/internal:xcodeproj.bzl", _xcodeproj = "xcodeproj")

# Re-exporting providers
InputFileAttributesInfo = _InputFileAttributesInfo

# Re-exporting rules
xcodeproj = _xcodeproj
