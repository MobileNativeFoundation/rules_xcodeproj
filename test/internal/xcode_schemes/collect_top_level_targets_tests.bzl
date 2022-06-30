"""Tests for `xcode_schemes.collect_top_level_targets`"""

load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _no_top_level_targets_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

no_top_level_targets_test = unittest.make(_no_top_level_targets_test)

def _empty_schemes_list_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

empty_schemes_list_test = unittest.make(_empty_schemes_list_test)

def _single_scheme_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

single_scheme_test = unittest.make(_single_scheme_test)

def _list_of_schemes_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

list_of_schemes_test = unittest.make(_list_of_schemes_test)

def collect_top_level_targets_test_suite(name):
    return unittest.suite(
        name,
        no_top_level_targets_test,
        empty_schemes_list_test,
        single_scheme_test,
        list_of_schemes_test,
    )
