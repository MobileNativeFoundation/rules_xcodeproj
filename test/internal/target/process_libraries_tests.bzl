"""Tests for platform processing functions."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//xcodeproj/internal:target.bzl", "testable")

process_libraries = testable.process_libraries

def _process_libraries_test_impl(ctx):
    env = unittest.begin(ctx)

    links, required_links = process_libraries(
        product_type = ctx.attr.product_type,
        test_host_libraries = depset([
            struct(path = path) for path in ctx.attr.test_host_libraries
        ]),
        links = ctx.attr.links,
        required_links = ctx.attr.required_links,
    )

    asserts.equals(
        env,
        ctx.attr.expected_links,
        links,
        "links",
    )
    asserts.equals(
        env,
        ctx.attr.expected_required_links,
        required_links,
        "required_links",
    )

    return unittest.end(env)

process_libraries_test = unittest.make(
    impl = _process_libraries_test_impl,
    attrs = {
        "product_type": attr.string(mandatory = True),
        "test_host_libraries": attr.string_list(mandatory = True),
        "links": attr.string_list(mandatory = True),
        "required_links": attr.string_list(mandatory = True),
        "expected_links": attr.string_list(mandatory = True),
        "expected_required_links": attr.string_list(mandatory = True),
    },
)

def process_libraries_test_suite(name):
    """Test suite for `process_libraries`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
        *,
        name,
        product_type,
        test_host_libraries,
        links,
        required_links,
        expected_links,
        expected_required_links):
        test_names.append(name)
        process_libraries_test(
            name = name,
            product_type = product_type,
            test_host_libraries = test_host_libraries,
            links = links,
            required_links = required_links,
            expected_links = expected_links,
            expected_required_links = expected_required_links,
            timeout = "short",
        )

    # No changes

    _add_test(
        name = "{}_ui_test".format(name),
        product_type = "com.apple.product-type.bundle.ui-test",
        test_host_libraries = ["libfoo.a"],
        links = ["libfoo.a", "libbar.a"],
        required_links = ["libfoo.a"],
        expected_links = ["libfoo.a", "libbar.a"],
        expected_required_links = ["libfoo.a"],
    )

    # Changes

    _add_test(
        name = "{}_unit_test".format(name),
        product_type = "com.apple.product-type.bundle.unit-test",
        test_host_libraries = ["libfoo.a"],
        links = ["libfoo.a", "libbar.a"],
        required_links = ["libfoo.a"],
        expected_links = ["libbar.a"],
        expected_required_links = [],
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
