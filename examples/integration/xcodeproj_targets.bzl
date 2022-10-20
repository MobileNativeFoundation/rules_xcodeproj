"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_target",
    "top_level_targets",
    "xcode_schemes",
)

CONFIG = "rules_xcodeproj_integration"

EXTRA_FILES = [
    "//:README.md",
]

ASSOCIATED_EXTRA_FILES = {
    "//iOSApp/Source:iOSApp": ["//iOSApp:ownership.yaml"],
    "//Lib": ["//Lib:README.md"],
}

UNFOCUSED_TARGETS = [
    "//Lib:LibFramework.iOS",
]

XCODEPROJ_TARGETS = [
    top_level_target(
        label = "//CommandLine/CommandLineTool",
        target_environments = ["device"],
    ),
    top_level_target(
        label = "//CommandLine/Tests:CommandLineToolTests",
        target_environments = ["device"],
    ),
    top_level_targets(
        labels = [
            "//iOSApp",
            "//Lib/dist/dynamic:iOS",
            "//Lib/dist/dynamic:tvOS",
            "//Lib/dist/dynamic:watchOS",
            "//tvOSApp",
        ],
        target_environments = ["device", "simulator"],
    ),
    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests",
    "//iMessageApp",
    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
    "//macOSApp/Source:macOSApp",
    "//macOSApp/Test/UITests:macOSAppUITests",
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

SCHEME_AUTOGENERATION_MODE = "all"

def get_xcode_schemes():
    return [
        xcode_schemes.scheme(
            name = "iOSAppUnitTests_Scheme",
            test_action = xcode_schemes.test_action(
                env = {
                    "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEMEVAR": "TRUE",
                },
                targets = [
                    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
                    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests",
                ],
                post_actions = [
                    xcode_schemes.pre_post_action(
                        name = "Run After Tests",
                        script = "echo \"Hi\"",
                        expand_variables_based_on = "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests"
                    ),
                ]
            ),
        ),
    ]
