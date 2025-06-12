"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_targets",
    "xcschemes",
)

XCODEPROJ_TARGETS = [
    top_level_targets(
        labels = [
            "//iOSApp",
            "//Lib:LibDynamic",
        ],
        target_environments = ["device", "simulator"],
    ),
    "//iOSApp/Test/MixedUnitTests:iOSAppMixedUnitTests",
    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests",
    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTestSuite",
    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTestSuite",
    "//iOSApp/Test/UITests:iOSAppUITestSuite",
    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests_macro",
    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests_macro_with_bundle_name",
    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTestSuite_macro",
    "//iOSApp/Test/UITests:iOSAppUITests_macro",
    "//iOSApp/Test/UITests:iOSAppUITestSuite_macro",
]

IOS_BUNDLE_ID = "rules-xcodeproj.example"
TEAMID = "V82V4GQZXM"

SCHEME_AUTOGENERATION_MODE = "all"

XCSCHEMES = [
    xcschemes.scheme(
        name = "iOSAppUnitTests_Scheme",
        test = xcschemes.test(
            env = {
                "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEMEVAR": "TRUE",
            },
            test_targets = [
                xcschemes.test_target(
                    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests",
                    post_actions = [
                        xcschemes.pre_post_actions.launch_script(
                            title = "Run After Tests",
                            script_text = "echo \"Hi\"",
                        ),
                    ],
                ),
            ],
        ),
    ),
]

def get_extra_files():
    return [
        "//iOSApp:extra_files",
    ]
