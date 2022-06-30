"""Tests for `xcode_schemes.collect_top_level_targets`"""

load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _collect_top_level_targets_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

collect_top_level_targets_test = unittest.make(_collect_top_level_targets_test)

def collect_top_level_targets_test_suite(name):
    return unittest.suite(
        "collect_top_level_targets_tests",
        collect_top_level_targets_test,
    )
