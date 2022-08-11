"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load("//xcodeproj:xcodeproj.bzl", "xcode_schemes")

UNFOCUSED_TARGETS = [
    "@com_github_tadija_aexml//:AEXML",
]

_APP_TARGET = "//tools/generator"
_TEST_TARGET = "//tools/generator/test:tests"

TOP_LEVEL_TARGETS = [_APP_TARGET, _TEST_TARGET]

SCHEME_AUTOGENERATION_MODE = "none"

def get_xcode_schemes():
    return [
        xcode_schemes.scheme(
            name = "generator",
            # The build_action in this example is not necessary for the scheme
            # to work. It is here to test that customized build_for settings
            # propagate properly.
            build_action = xcode_schemes.build_action([
                xcode_schemes.build_target(
                    _APP_TARGET,
                    xcode_schemes.build_for(archiving = True),
                ),
            ]),
            launch_action = xcode_schemes.launch_action(_APP_TARGET),
            test_action = xcode_schemes.test_action([_TEST_TARGET]),
        ),
    ]
