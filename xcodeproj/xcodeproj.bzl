load(
    "//xcodeproj/internal:providers.bzl",
    _InputFileAttributesInfo = "InputFileAttributesInfo",
)
load("//xcodeproj/internal:xcodeproj.bzl", _xcodeproj = "xcodeproj")

xcodeproj = _xcodeproj
InputFileAttributesInfo = _InputFileAttributesInfo
