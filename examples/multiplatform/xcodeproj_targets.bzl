"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "top_level_target",
)

XCODEPROJ_TARGETS = [
    "//examples/multiplatform/iMessageApp",
    top_level_target(
        label = "//examples/multiplatform/iOSApp",
        target_environments = ["device", "simulator"],
    ),
    top_level_target(
        label = "//examples/multiplatform/tvOSApp",
        target_environments = ["device", "simulator"],
    ),
    top_level_target(
        label = "//examples/multiplatform/Tool",
        target_environments = ["device"],
    ),
]

IOS_BUNDLE_ID = "io.buildbuddy.example"
TEAMID = "V82V4GQZXM"

APP_CLIP_BUNDLE_ID = "{}.app-clip".format(IOS_BUNDLE_ID)
TVOS_BUNDLE_ID = IOS_BUNDLE_ID
WATCHOS_BUNDLE_ID = "{}.watch".format(IOS_BUNDLE_ID)
