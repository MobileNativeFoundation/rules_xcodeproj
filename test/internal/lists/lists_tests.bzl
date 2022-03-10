load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//xcodeproj/internal:lists.bzl", "lists")

def _flattened_key_values_to_dict_test(ctx):
    env = unittest.begin(ctx)

    # Empty iterable
    actual = lists.flattened_key_values_to_dict([])
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
    actual = lists.flattened_key_values_to_dict(iterable)
    expected = {
        "key0": ["key0_value"],
        "key1": ["key1_value"],
        "key2": ["key2_value"],
    }
    asserts.equals(env, expected, actual, "Sort multiple items.")

    return unittest.end(env)

flattened_key_values_to_dict_test = unittest.make(_flattened_key_values_to_dict_test)

def _dict_to_flattened_key_values_test(ctx):
    env = unittest.begin(ctx)

    # Empty dict
    actual = lists.dict_to_flattened_key_values({})
    expected = []
    asserts.equals(env, expected, actual, "Empty dict.")

    # Empty dict
    key_values_dict = {
        "key0": ["key0_value"],
        "key1": ["key1_value"],
        "key2": ["key2_value"],
    }
    actual = lists.dict_to_flattened_key_values(key_values_dict)
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

dict_to_flattened_key_values_test = unittest.make(_dict_to_flattened_key_values_test)

def lists_test_suite():
    return unittest.suite(
        "lists_tests",
        flattened_key_values_to_dict_test,
        dict_to_flattened_key_values_test,
    )
