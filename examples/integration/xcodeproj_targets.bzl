"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "top_level_target",
)

CONFIG = "rules_xcodeproj_integration"

XCODEPROJ_TARGETS = [
    top_level_target(
        label = "//CommandLine/CommandLineTool",
        target_environments = ["device"],
    ),
    top_level_target(
        label = "//CommandLine/Tests:CommandLineToolTests",
        target_environments = ["device"],
    ),
    "//iMessageApp",
    top_level_target(
        label = "//iOSApp/Source:iOSApp",
        target_environments = ["device", "simulator"],
    ),
    "//macOSApp/Source:macOSApp",
    "//macOSApp/Test/UITests:macOSAppUITests",
    top_level_target(
        label = "//tvOSApp/Source:tvOSApp",
        target_environments = ["device", "simulator"],
    ),
    "//tvOSApp/Test/UITests:tvOSAppUITests",
    "//tvOSApp/Test/UnitTests:tvOSAppUnitTests",
    "//watchOSApp/Test/UITests:watchOSAppUITests",
    "//watchOSAppExtension/Test/UnitTests:watchOSAppExtensionUnitTests",
]

IOS_BUNDLE_ID = "io.buildbuddy.example"
TEAMID = "V82V4GQZXM"

APP_CLIP_BUNDLE_ID = "{}.app-clip".format(IOS_BUNDLE_ID)
TVOS_BUNDLE_ID = IOS_BUNDLE_ID
WATCHOS_BUNDLE_ID = "{}.watch".format(IOS_BUNDLE_ID)
