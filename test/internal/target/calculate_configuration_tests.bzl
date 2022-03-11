"""Tests for platform processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:target.bzl", "testable")

calculate_configuration = testable.calculate_configuration

def _calculate_configuration_test_impl(ctx):
    env = unittest.begin(ctx)

    configuration = calculate_configuration(bin_dir_path = ctx.attr.bin_dir)

    asserts.equals(
        env,
        ctx.attr.expected_configuration,
        configuration,
        "configuration",
    )

    return unittest.end(env)

calculate_configuration_test = unittest.make(
    impl = _calculate_configuration_test_impl,
    attrs = {
        "bin_dir": attr.string(mandatory = True),
        "expected_configuration": attr.string(mandatory = True),
    },
)

def calculate_configuration_test_suite(name):
    """Test suite for `calculate_configuration`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,
            bin_dir_path,
            expected_configuration):
        test_names.append(name)
        calculate_configuration_test(
            name = name,
            bin_dir = bin_dir_path,
            expected_configuration = expected_configuration,
            timeout = "short",
        )

    # Valid

    _add_test(
        name = "{}_normal".format(name),
        bin_dir_path = "bazel-out/ios-arm64-dbg-ST-something/bin",
        expected_configuration = "ios-arm64-dbg-ST-something",
    )

    # Invalid

    _add_test(
        name = "{}_too_short".format(name),
        bin_dir_path = "bazel-out",
        expected_configuration = "",
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
