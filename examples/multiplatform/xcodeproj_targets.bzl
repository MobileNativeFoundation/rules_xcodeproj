"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

XCODEPROJ_TARGETS = [
    "//examples/multiplatform:device_targets",
]

IOS_BUNDLE_ID = "io.buildbuddy.example"
TEAMID = "V82V4GQZXM"

APP_CLIP_BUNDLE_ID = "{}.app-clip".format(IOS_BUNDLE_ID)
TVOS_BUNDLE_ID = IOS_BUNDLE_ID
WATCHOS_BUNDLE_ID = "{}.watch".format(IOS_BUNDLE_ID)
