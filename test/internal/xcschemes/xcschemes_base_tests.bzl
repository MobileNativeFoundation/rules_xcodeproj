"""Tests for the `xcschemes` module."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal/xcschemes:xcschemes.bzl",
    "xcschemes",
)

def _xcschemes_base_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange / Act

    result = json.decode(ctx.attr.result)
    expected = json.decode(ctx.attr.expected)

    # Assert

    asserts.equals(
        env,
        expected,
        result,
    )

    return unittest.end(env)

xcschemes_base_test = unittest.make(
    impl = _xcschemes_base_test_impl,
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "result": attr.string(mandatory = True),

        # Expected
        "expected": attr.string(mandatory = True),
    },
)

def xcschemes_base_test_suite(name):
    """Test suite for `xcschemes`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,

            # Inputs
            result,

            # Expected
            expected):
        test_names.append(name)
        xcschemes_base_test(
            name = name,

            # Inputs
            result = json.encode(result),

            # Expected
            expected = json.encode(expected),
        )

    # env_value

    _add_test(
        name = "{}_env_value_default".format(name),

        # Inputs
        result = xcschemes.env_value(value = "test value"),

        # Expected
        expected = struct(
            enabled = "1",
            value = "test value",
        ),
    )

    _add_test(
        name = "{}_env_value_empty".format(name),

        # Inputs
        result = xcschemes.env_value(value = ""),

        # Expected
        expected = struct(
            enabled = "1",
            value = "",
        ),
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
