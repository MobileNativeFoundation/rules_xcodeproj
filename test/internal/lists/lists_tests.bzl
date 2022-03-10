load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//xcodeproj/internal:lists.bzl", "lists")

def _sort_flattened_key_values_test(ctx):
    env = unittest.begin(ctx)

    unittest.fail(env, "IMPLEMENT ME!")
    asserts.equals(env, True, False)
    lists.sort_flattend_key_values()

    return unittest.end(env)

sort_flattened_key_values_test = unittest.make(_sort_flattened_key_values_test)

def lists_test_suite():
    return unittest.suite(
        "lists_tests",
        sort_flattened_key_values_test,
    )
