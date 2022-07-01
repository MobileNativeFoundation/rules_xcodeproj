"""Tests for `bazel_labels.absolute`"""

load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _absolute_label_without_repo_name_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

absolute_label_without_repo_name_test = unittest.make(_absolute_label_without_repo_name_test)

def _absolute_label_with_repo_name_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

absolute_label_with_repo_name_test = unittest.make(_absolute_label_with_repo_name_test)

def _relative_label_with_colon_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

relative_label_with_colon_test = unittest.make(_relative_label_with_colon_test)

def _relative_label_without_colon_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    return unittest.end(env)

relative_label_without_colon_test = unittest.make(_relative_label_without_colon_test)

def absolute_test_suite(name):
    return unittest.suite(
        name,
        absolute_label_without_repo_name_test,
        absolute_label_with_repo_name_test,
        relative_label_with_colon_test,
        relative_label_without_colon_test,
    )
