"""Tests for `bazel_labels.absolute`"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:bazel_labels.bzl",
    "make_bazel_labels",
    "make_stub_name_resolver",
)

bazel_labels = make_bazel_labels(
    name_resolver = make_stub_name_resolver(
        repo_name = "@",
        pkg_name = "Sources/Foo",
    ),
)

def _absolute_label_without_repo_name_test(ctx):
    env = unittest.begin(ctx)

    value = "//Sources/Foo:chicken"

    actual = bazel_labels.parse(value)
    expected = bazel_labels.create(
        repository_name = "@",
        package = "Sources/Foo",
        name = "chicken",
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

absolute_label_without_repo_name_test = unittest.make(_absolute_label_without_repo_name_test)

def _absolute_label_with_repo_name_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    value = "@my_dep//Sources/Foo:chicken"

    return unittest.end(env)

absolute_label_with_repo_name_test = unittest.make(_absolute_label_with_repo_name_test)

def _absolute_label_without_explicit_name_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    value = "//Sources/Foo"

    return unittest.end(env)

absolute_label_without_explicit_name_test = unittest.make(_absolute_label_without_explicit_name_test)

def _relative_label_with_colon_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    value = ":chicken"

    return unittest.end(env)

relative_label_with_colon_test = unittest.make(_relative_label_with_colon_test)

def _relative_label_without_colon_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")

    value = "chicken"

    return unittest.end(env)

relative_label_without_colon_test = unittest.make(_relative_label_without_colon_test)

def parse_test_suite(name):
    return unittest.suite(
        name,
        absolute_label_without_repo_name_test,
        absolute_label_with_repo_name_test,
        absolute_label_without_explicit_name_test,
        relative_label_with_colon_test,
        relative_label_without_colon_test,
    )
