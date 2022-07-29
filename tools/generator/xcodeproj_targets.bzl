"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load("//xcodeproj:xcodeproj.bzl", "xcode_schemes")

UNFOCUSED_TARGETS = [
    "@com_github_tadija_aexml//:AEXML",
]

_APP_TARGET = "//tools/generator"
_TEST_TARGET = "//tools/generator/test:tests"

TOP_LEVEL_TARGETS = [_APP_TARGET, _TEST_TARGET] + UNFOCUSED_TARGETS

SCHEME_AUTOGENERATION_MODE = "none"

def get_xcode_schemes():
    return [
        xcode_schemes.scheme(
            name = "generator",
            launch_action = xcode_schemes.launch_action(_APP_TARGET),
            test_action = xcode_schemes.test_action([_TEST_TARGET]),
        ),
    ]
