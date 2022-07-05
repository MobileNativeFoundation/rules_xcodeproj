"""Tests for `xcode_schemes_internal.replace_labels_with_target_ids`"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:xcode_schemes_internal.bzl", "xcode_schemes_internal")

_CONFIGURATION = "darwin_x86_64-fastbuild-ST-d53d69b6b8c1"

def _all_actions_specified_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

all_actions_specified_test = unittest.make(_all_actions_specified_test)

def _no_actions_specified_test(ctx):
    env = unittest.begin(ctx)

    scheme = xcode_schemes_internal.scheme(name = "Foo")
    actual = xcode_schemes_internal.replace_labels_with_target_ids(
        scheme = scheme,
        configuration = _CONFIGURATION,
    )
    expected = scheme
    asserts.equals(env, expected, actual)

    return unittest.end(env)

no_actions_specified_test = unittest.make(_no_actions_specified_test)

def replace_labels_with_target_ids_test_suite(name):
    return unittest.suite(
        name,
        all_actions_specified_test,
        no_actions_specified_test,
    )
