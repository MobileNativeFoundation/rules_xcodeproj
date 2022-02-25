"""Tests for linking options processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:utils.bzl", "stringify_dict")
load("//xcodeproj/internal:opts.bzl", "testable")

process_linker_opts = testable.process_linker_opts

def _process_linker_opts_test_impl(ctx):
    env = unittest.begin(ctx)

    build_settings = {}
    process_linker_opts(
        linkopts = ctx.attr.linkopts,
        build_settings = build_settings
    )
    string_build_settings = stringify_dict(build_settings)

    asserts.equals(
        env,
        ctx.attr.expected_build_settings,
        string_build_settings,
        "build_settings",
    )

    return unittest.end(env)

process_linker_opts_test = unittest.make(
    impl = _process_linker_opts_test_impl,
    attrs = {
        "linkopts": attr.string_list(mandatory = True),
        "expected_build_settings": attr.string_dict(mandatory = True),
    },
)

def process_linker_opts_test_suite(name):
    """Test suite for `process_linker_opts`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
        *,
        name,
        linkopts,
        expected_build_settings):
        test_names.append(name)
        process_linker_opts_test(
            name = name,
            linkopts = linkopts,
            expected_build_settings = expected_build_settings,
        )

    # Base

    _add_test(
        name = "{}_empty".format(name),
        linkopts = [],
        expected_build_settings = {},
    )

    _add_test(
        name = "{}_passthrough".format(name),
        linkopts = [
            "-something",
            "-another-thing",
        ],
        expected_build_settings = {
            "OTHER_LDFLAGS": '''["-something", "-another-thing"]''',
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
