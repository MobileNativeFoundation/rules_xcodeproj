"""Tests for module name build setting functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//xcodeproj/internal:build_settings.bzl", "testable")

calculate_module_name = testable.calculate_module_name

def _calculate_module_name_test_impl(ctx):
    env = unittest.begin(ctx)

    module_name = calculate_module_name(
        label = ctx.attr.label.label,
        module_name = ctx.attr.module_name,
    )

    asserts.equals(
        env,
        ctx.attr.expected_module_name,
        module_name,
        "module_name",
    )

    return unittest.end(env)

calculate_module_name_test = unittest.make(
    impl = _calculate_module_name_test_impl,
    attrs = {
        "label": attr.label(mandatory = True),
        "module_name": attr.string(mandatory = False),
        "expected_module_name": attr.string(mandatory = True),
    },
)

def calculate_module_name_test_suite(name):
    """Test suite for `calculate_module_name`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
        *,
        name,
        label,
        module_name,
        expected_module_name):
        test_names.append(name)
        calculate_module_name_test(
            name = name,
            label = label,
            module_name = module_name,
            expected_module_name = expected_module_name,
            timeout = "short",
        )

    # Module name

    _add_test(
        name = "{}_module_name".format(name),
        label = Label("//tools/generator:generator"),
        module_name = "Bar",
        expected_module_name = "Bar",
    )

    # Label

    _add_test(
        name = "{}_in_repo_label".format(name),
        label = Label("//tools/generator:generator"),
        module_name = None,
        expected_module_name = "tools_generator_generator",
    )

    _add_test(
        name = "{}_external_label".format(name),
        label = Label("@build_bazel_rules_swift//tools/worker:worker"),
        module_name = None,
        expected_module_name = "build_bazel_rules_swift_tools_worker_worker",
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
