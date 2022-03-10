"""Tests for module name build setting functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:build_settings.bzl", "get_targeted_device_family")

def _get_targeted_device_family_test_impl(ctx):
    env = unittest.begin(ctx)

    targeted_device_family = get_targeted_device_family(
        families = ctx.attr.families,
    )

    asserts.equals(
        env,
        ctx.attr.expected_targeted_device_family or None,
        targeted_device_family,
        "targeted_device_family",
    )

    return unittest.end(env)

get_targeted_device_family_test = unittest.make(
    impl = _get_targeted_device_family_test_impl,
    attrs = {
        "expected_targeted_device_family": attr.string(mandatory = False),
        "families": attr.string_list(mandatory = True),
    },
)

def get_targeted_device_family_test_suite(name):
    """Test suite for `get_targeted_device_family`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,
            families,
            expected_targeted_device_family):
        test_names.append(name)
        get_targeted_device_family_test(
            name = name,
            families = families,
            expected_targeted_device_family = expected_targeted_device_family,
            timeout = "short",
        )

    # macOS

    _add_test(
        name = "{}_mac".format(name),
        families = ["mac"],
        expected_targeted_device_family = None,
    )

    # iOS

    _add_test(
        name = "{}_iphone".format(name),
        families = ["iphone"],
        expected_targeted_device_family = "1",
    )

    _add_test(
        name = "{}_ipad".format(name),
        families = ["ipad"],
        expected_targeted_device_family = "2",
    )

    _add_test(
        name = "{}_universal".format(name),
        families = ["iphone", "ipad"],
        expected_targeted_device_family = "1,2",
    )

    # tvOS

    _add_test(
        name = "{}_tv".format(name),
        families = ["tv"],
        expected_targeted_device_family = "3",
    )

    # watchOS

    _add_test(
        name = "{}_watch".format(name),
        families = ["watch"],
        expected_targeted_device_family = "4",
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
