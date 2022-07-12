"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

XCODEPROJ_TARGETS = [
    "//examples/multiplatform:device_targets",
    "//examples/multiplatform/Tool",
]

TEAMID = "V82V4GQZXM"

IOS_BUNDLE_ID = "io.buildbuddy.example"
IMESSAGE_APP_BUNDLE_ID = "{}.imessage-app".format(IOS_BUNDLE_ID)
TVOS_BUNDLE_ID = IOS_BUNDLE_ID
WATCHOS_BUNDLE_ID = "{}.watch".format(IOS_BUNDLE_ID)
