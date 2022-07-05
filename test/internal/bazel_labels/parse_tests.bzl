"""Tests for `bazel_labels.parse`"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:bazel_labels.bzl",
    "make_bazel_labels",
)

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:workspace_name_resolvers.bzl",
    "make_stub_workspace_name_resolvers",
)

bazel_labels = make_bazel_labels(
    workspace_name_resolvers = make_stub_workspace_name_resolvers(
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

    value = "@my_dep//Sources/Foo:chicken"
    actual = bazel_labels.parse(value)
    expected = bazel_labels.create(
        repository_name = "@my_dep",
        package = "Sources/Foo",
        name = "chicken",
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

absolute_label_with_repo_name_test = unittest.make(_absolute_label_with_repo_name_test)

def _absolute_label_without_explicit_name_test(ctx):
    env = unittest.begin(ctx)

    value = "//Sources/Foo"
    actual = bazel_labels.parse(value)
    expected = bazel_labels.create(
        repository_name = "@",
        package = "Sources/Foo",
        name = "Foo",
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

absolute_label_without_explicit_name_test = unittest.make(_absolute_label_without_explicit_name_test)

def _relative_label_with_colon_test(ctx):
    env = unittest.begin(ctx)

    value = ":chicken"
    actual = bazel_labels.parse(value)
    expected = bazel_labels.create(
        repository_name = "@",
        package = "Sources/Foo",
        name = "chicken",
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

relative_label_with_colon_test = unittest.make(_relative_label_with_colon_test)

def _relative_label_without_colon_test(ctx):
    env = unittest.begin(ctx)

    value = "chicken"
    actual = bazel_labels.parse(value)
    expected = bazel_labels.create(
        repository_name = "@",
        package = "Sources/Foo",
        name = "chicken",
    )
    asserts.equals(env, expected, actual)

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
