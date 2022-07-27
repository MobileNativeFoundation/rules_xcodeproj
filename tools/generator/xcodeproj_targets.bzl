"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load("//xcodeproj:xcodeproj.bzl", "xcode_schemes")

UNFOCUSED_TARGETS = [
    "@com_github_tadija_aexml//:AEXML",
]

SCHEME_AUTOGENERATION_MODE = "none"

def get_xcode_schemes():
    return [
        xcode_schemes.scheme(
            name = "generator",
            launch_action = xcode_schemes.launch_action(
                "//tools/generator",
            ),
            test_action = xcode_schemes.test_action([
                "//tools/generator/test:tests",
            ]),
        ),
    ]
