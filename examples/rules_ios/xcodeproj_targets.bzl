"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_targets",
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
]

IOS_BUNDLE_ID = "rules-xcodeproj.example"
TEAMID = "V82V4GQZXM"

SCHEME_AUTOGENERATION_MODE = "all"
