"""Tests for xcodeproj_tests."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//xcodeproj:testing.bzl", "xcodeproj_tests")

def _from_fixture_test(ctx):
    env = unittest.begin(ctx)

    # Specify target
    actual = xcodeproj_tests.from_fixture("//path/to/pkg:custom_xcodeproj")
    expected = struct(
        basename = "pkg",
        target_under_test = "//path/to/pkg:custom_xcodeproj",
        expected_spec = "@//path/to/pkg:spec.json",
        expected_xcodeproj = "@//path/to/pkg:custom_xcodeproj_output",
    )
    asserts.equals(env, expected, actual, "Specifying fixture target")

    # Specify everything
    actual = xcodeproj_tests.from_fixture(
        "//path/to/pkg:custom_xcodeproj",
        basename = "custom_basename",
        expected_spec = "//path/to/pkg:custom_spec.json",
        expected_xcodeproj = "//path/to/pkg:custom_xcodeproj_output",
    )
    expected = struct(
        basename = "custom_basename",
        target_under_test = "//path/to/pkg:custom_xcodeproj",
        expected_spec = "//path/to/pkg:custom_spec.json",
        expected_xcodeproj = "//path/to/pkg:custom_xcodeproj_output",
    )
    asserts.equals(env, expected, actual, "Specifying everything")

    return unittest.end(env)

from_fixture_test = unittest.make(_from_fixture_test)

def _from_fixtures_test(ctx):
    env = unittest.begin(ctx)

    packages = ["//foo", "//bar"]
    actual = xcodeproj_tests.from_fixtures(packages)
    expected = [
        xcodeproj_tests.from_fixture("//foo"),
        xcodeproj_tests.from_fixture("//bar"),
    ]
    asserts.equals(env, expected, actual, "Multiple fixture packages")

    return unittest.end(env)

from_fixtures_test = unittest.make(_from_fixtures_test)

def xcodeproj_tests_test_suite(name):
    return unittest.suite(
        name,
        from_fixture_test,
        from_fixtures_test,
    )
