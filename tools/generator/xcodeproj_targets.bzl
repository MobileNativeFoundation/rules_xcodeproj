"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("//xcodeproj:xcodeproj.bzl", "xcode_schemes")

GENERATOR_SCHEME_AUTOGENERATION_MODE = "none"

def get_xcode_schemes():
    return [
        xcode_schemes.scheme(
            name = "generator",
            launch_action = xcode_schemes.launch_action(
                "//tools/generator:generator",
            ),
            test_action = xcode_schemes.test_action([
                "//tools/generator/test:tests",
            ]),
        ),
    ]

def get_xcodeproj_targets():
    return sets.to_list(
        xcode_schemes.collect_top_level_targets(
            get_xcode_schemes(),
        ),
    )
