"""Tests for platform processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:utils.bzl", "stringify_dict")
load("//xcodeproj/internal:platform.bzl", "testable")

generate_platform_information = testable.generate_platform_information

def _generate_platform_information_test_impl(ctx):
    env = unittest.begin(ctx)

    build_settings = {}
    platform = generate_platform_information(
        platform = getattr(apple_common.platform, ctx.attr.platform_key),
        arch = ctx.attr.arch,
        minimum_os_version = ctx.attr.minimum_os_version,
        minimum_deployment_os_version = ctx.attr.minimum_deployment_os_version,
        build_settings = build_settings,
    )
    string_platform = stringify_dict(platform)
    string_build_settings = stringify_dict(build_settings)

    asserts.equals(
        env,
        ctx.attr.expected_platform_dict,
        string_platform,
        "platform",
    )
    asserts.equals(
        env,
        ctx.attr.expected_build_settings,
        string_build_settings,
        "build_settings",
    )

    return unittest.end(env)

generate_platform_information_test = unittest.make(
    impl = _generate_platform_information_test_impl,
    attrs = {
        "platform_key": attr.string(mandatory = True),
        "arch": attr.string(mandatory = True),
        "minimum_os_version": attr.string(mandatory = True),
        "minimum_deployment_os_version": attr.string(mandatory = False),
        "expected_build_settings": attr.string_dict(mandatory = True),
        "expected_platform_dict": attr.string_dict(mandatory = True),
    },
)

def generate_platform_information_test_suite(name):
    """Test suite for `generate_platform_information`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
        *,
        name,
        platform_key,
        arch,
        minimum_os_version,
        minimum_deployment_os_version,
        expected_platform_dict,
        expected_build_settings):
        test_names.append(name)
        generate_platform_information_test(
            name = name,
            platform_key = platform_key,
            arch = arch,
            minimum_os_version = minimum_os_version,
            minimum_deployment_os_version = minimum_deployment_os_version,
            expected_platform_dict = expected_platform_dict,
            expected_build_settings = stringify_dict(expected_build_settings),
            timeout = "short",
        )

    # Minimum OS version

    _add_test(
        name = "{}_minimum_os_version".format(name),
        platform_key = "tvos_simulator",
        arch = "wild",
        minimum_os_version = "12.0",
        minimum_deployment_os_version = None,
        expected_platform_dict = {
            "os": "tvOS",
            "arch": "wild",
            "minimum_os_version": "12.0",
            "environment": "Simulator",
        },
        expected_build_settings = {
            "SDKROOT": "appletvos",
            "TVOS_DEPLOYMENT_TARGET": "12.0",
        },
    )

    _add_test(
        name = "{}_deployment_os_version".format(name),
        platform_key = "ios_simulator",
        arch = "x86_64",
        minimum_os_version = "11.0",
        minimum_deployment_os_version = "13.0",
        expected_platform_dict = {
            "os": "iOS",
            "arch": "x86_64",
            "minimum_os_version": "11.0",
            "environment": "Simulator",
        },
        expected_build_settings = {
            "SDKROOT": "iphoneos",
            "IPHONEOS_DEPLOYMENT_TARGET": "13.0",
        },
    )

    # Environment

    _add_test(
        name = "{}_no_environment".format(name),
        platform_key = "macos",
        arch = "arm64",
        minimum_os_version = "12.1",
        minimum_deployment_os_version = None,
        expected_platform_dict =  {
            "os": "macOS",
            "arch": "arm64",
            "minimum_os_version": "12.1",
        },
        expected_build_settings = {
            "SDKROOT": "macosx",
            "MACOSX_DEPLOYMENT_TARGET": "12.1",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
