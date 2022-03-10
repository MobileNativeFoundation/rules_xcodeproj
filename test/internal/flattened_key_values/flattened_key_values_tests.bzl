"""Tests for flattened_key_values module."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:flattened_key_values.bzl", "flattened_key_values")

def _to_dict_test(ctx):
    env = unittest.begin(ctx)

    # Empty iterable
    actual = flattened_key_values.to_dict([])
    expected = {}
    asserts.equals(env, expected, actual, "Empty iterable.")

    # Sort multiple items
    iterable = [
        "key1",
        ["key1_value"],
        "key0",
        ["key0_value"],
        "key2",
        ["key2_value"],
    ]
    actual = flattened_key_values.to_dict(iterable)
    expected = {
        "key0": ["key0_value"],
        "key1": ["key1_value"],
        "key2": ["key2_value"],
    }
    asserts.equals(env, expected, actual, "Sort multiple items.")

    return unittest.end(env)

to_dict_test = unittest.make(_to_dict_test)

def _to_list_test(ctx):
    env = unittest.begin(ctx)

    # Empty dict
    actual = flattened_key_values.to_list({})
    expected = []
    asserts.equals(env, expected, actual, "Empty dict.")

    # Empty dict
    key_values_dict = {
        "key0": ["key0_value"],
        "key1": ["key1_value"],
        "key2": ["key2_value"],
    }
    actual = flattened_key_values.to_list(key_values_dict)
    expected = [
        "key0",
        ["key0_value"],
        "key1",
        ["key1_value"],
        "key2",
        ["key2_value"],
    ]
    asserts.equals(env, expected, actual, "Multiple items.")

    return unittest.end(env)

to_list_test = unittest.make(_to_list_test)

def _sort_test(ctx):
    env = unittest.begin(ctx)

    # Empty iterable
    actual = flattened_key_values.sort([])
    expected = []
    asserts.equals(env, expected, actual, "Empty iterable.")

    # Multiple items
    iterable = [
        "key1",
        ["key1_value"],
        "key0",
        ["key0_value"],
        "key2",
        ["key2_value"],
    ]
    actual = flattened_key_values.sort(iterable)
    expected = [
        "key0",
        ["key0_value"],
        "key1",
        ["key1_value"],
        "key2",
        ["key2_value"],
    ]
    asserts.equals(env, expected, actual, "Sort multiple items.")

    return unittest.end(env)

sort_test = unittest.make(_sort_test)

def flattened_key_values_test_suite():
    return unittest.suite(
        "lists_tests",
        to_dict_test,
        to_list_test,
        sort_test,
    )
