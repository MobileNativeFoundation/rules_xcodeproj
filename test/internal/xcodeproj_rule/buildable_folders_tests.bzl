"""Tests for `xcodeproj_rule` buildable-folder gating."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:xcodeproj_rule.bzl",
    "xcodeproj_rule_testable",
)

def _buildable_folders_test_impl(ctx):
    env = unittest.begin(ctx)

    actual = xcodeproj_rule_testable.buildable_folders_error(
        buildable_folders = ctx.attr.buildable_folders,
        minimum_xcode_version = ctx.attr.minimum_xcode_version,
    )

    if ctx.attr.expected_none:
        asserts.equals(env, None, actual)
    else:
        asserts.equals(env, ctx.attr.expected, actual)

    return unittest.end(env)

buildable_folders_test = unittest.make(
    impl = _buildable_folders_test_impl,
    attrs = {
        "buildable_folders": attr.bool(mandatory = True),
        "expected_none": attr.bool(default = False),
        "expected": attr.string(),
        "minimum_xcode_version": attr.string(mandatory = True),
    },
)

def buildable_folders_test_suite(name):
    buildable_folders_test(
        name = "{}_disabled_on_xcode15".format(name),
        buildable_folders = True,
        minimum_xcode_version = "15.4.0",
        expected = """\
`buildable_folders` requires Xcode 16 or newer, but `minimum_xcode_version` \
resolved to 15.4.0.

Either disable `buildable_folders` or set `minimum_xcode_version` to 16.0 or \
newer.
""",
    )

    buildable_folders_test(
        name = "{}_allowed_on_xcode16".format(name),
        buildable_folders = True,
        minimum_xcode_version = "16.0.0",
        expected_none = True,
    )

    buildable_folders_test(
        name = "{}_disabled_flag_has_no_error".format(name),
        buildable_folders = False,
        minimum_xcode_version = "15.4.0",
        expected_none = True,
    )

    native.test_suite(
        name = name,
        tests = [
            "{}_disabled_on_xcode15".format(name),
            "{}_allowed_on_xcode16".format(name),
            "{}_disabled_flag_has_no_error".format(name),
        ],
    )
