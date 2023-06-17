"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_targets",
    "xcode_schemes",
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

def get_xcode_schemes():
    return [
        xcode_schemes.scheme(
            name = "iOSAppUnitTests_Scheme",
            test_action = xcode_schemes.test_action(
                env = {
                    "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEMEVAR": "TRUE",
                },
                targets = [
                    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests",
                ],
                post_actions = [
                    xcode_schemes.pre_post_action(
                        name = "Run After Tests",
                        script = "echo \"Hi\"",
                        expand_variables_based_on = "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests",
                    ),
                ],
            ),
        ),
    ]
