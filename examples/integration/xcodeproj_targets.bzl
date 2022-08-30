"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "top_level_target",
)

XCODEPROJ_TARGETS = [
    "//examples/integration/iMessageApp",
    top_level_target(
        label = "//examples/integration/iOSApp",
        target_environments = ["device", "simulator"],
    ),
    "//examples/integration/macOSApp/Source:macOSApp",
    "//examples/integration/macOSApp/Test/UITests:macOSAppUITests",
    top_level_target(
        label = "//examples/integration/tvOSApp",
        target_environments = ["device", "simulator"],
    ),
    "//examples/integration/tvOSApp/Test/UITests:tvOSAppUITests",
    "//examples/integration/tvOSApp/Test/UnitTests:tvOSAppUnitTests",
    top_level_target(
        label = "//examples/integration/Tool",
        target_environments = ["device"],
    ),
    "//examples/integration/watchOSApp/Test/UITests:watchOSAppUITests",
    "//examples/integration/watchOSAppExtension/Test/UnitTests:watchOSAppExtensionUnitTests",
]

IOS_BUNDLE_ID = "io.buildbuddy.example"
TEAMID = "V82V4GQZXM"

APP_CLIP_BUNDLE_ID = "{}.app-clip".format(IOS_BUNDLE_ID)
TVOS_BUNDLE_ID = IOS_BUNDLE_ID
WATCHOS_BUNDLE_ID = "{}.watch".format(IOS_BUNDLE_ID)
