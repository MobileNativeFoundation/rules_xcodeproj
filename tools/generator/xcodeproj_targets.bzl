"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load("//xcodeproj:xcodeproj.bzl", "xcode_schemes")

UNFOCUSED_TARGETS = [
    "@com_github_tadija_aexml//:AEXML",
]

_APP_TARGET = "//tools/generator"
_TEST_TARGET = "//tools/generator/test:tests"

TOP_LEVEL_TARGETS = [_APP_TARGET, _TEST_TARGET]

SCHEME_AUTOGENERATION_MODE = "none"

# tl;dr The `tools/generator` custom Xcode schemes are wrapped in a function
# because they are shared with `//tools/generator:xcodeproj` and
# `//test/fixtures/generator:xcodeproj`.
#
# The Xcode schemes for `tools/generator` are loaded from a function because
# several of the `xcode_schemes` functions must be called on a BUILD file
# thread as they resolve and normalize Bazel labels. These functions use
# `bazel_labels.parse` which, in turn, use `workspace_name_resolvers`
# functions. It is the `workspace_name_resolvers` functions that must be called
# on a BUILD file thread.
#
# Most rules_xcodeproj clients will not need to wrap their custom scheme
# declarations in a function. They should be able to declare them directly in
# their BUILD files. Wrapping the declarations in a function is only necessary
# when sharing a set of custom schemes as is done with the fixture tests in
# this repository.

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
