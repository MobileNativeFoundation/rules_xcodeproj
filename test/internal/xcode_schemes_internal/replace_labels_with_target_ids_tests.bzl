"""Tests for `xcode_schemes_internal.replace_labels_with_target_ids`"""

load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _all_actions_specified_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

all_actions_specified_test = unittest.make(_all_actions_specified_test)

def _no_actions_specified_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

no_actions_specified_test = unittest.make(_no_actions_specified_test)

def replace_labels_with_target_ids_test_suite(name):
    return unittest.suite(
        name,
        all_actions_specified_test,
        no_actions_specified_test,
    )
