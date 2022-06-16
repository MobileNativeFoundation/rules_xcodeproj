"""Tests for platform processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:utils.bzl", "stringify_dict")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:platform.bzl", "platform_info")

def _platform_info_to_dto_test_impl(ctx):
    env = unittest.begin(ctx)

    build_settings = {}
    platform = struct(
        _platform = getattr(apple_common.platform, ctx.attr.platform_key),
        _arch = ctx.attr.arch,
        _minimum_os_version = ctx.attr.minimum_os_version,
        _minimum_deployment_os_version = ctx.attr.minimum_deployment_os_version,
    )
    dto = platform_info.to_dto(platform, build_settings = build_settings)
    string_platform = stringify_dict(dto)
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

platform_info_to_dto_test = unittest.make(
    impl = _platform_info_to_dto_test_impl,
    attrs = {
        "arch": attr.string(mandatory = True),
        "expected_build_settings": attr.string_dict(mandatory = True),
        "expected_platform_dict": attr.string_dict(mandatory = True),
        "minimum_deployment_os_version": attr.string(mandatory = False),
        "minimum_os_version": attr.string(mandatory = True),
        "platform_key": attr.string(mandatory = True),
    },
)

def platform_info_to_dto_test_suite(name):
    """Test suite for `platform_info.to_dto`.

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
        platform_info_to_dto_test(
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
        platform_key = "tvos_device",
        arch = "wild",
        minimum_os_version = "12.0",
        minimum_deployment_os_version = None,
        expected_platform_dict = {
            "arch": "wild",
            "minimum_os_version": "12.0",
            "name": "appletvos",
            "os": "tvos",
        },
        expected_build_settings = {
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
            "arch": "x86_64",
            "environment": "Simulator",
            "name": "iphonesimulator",
            "minimum_os_version": "11.0",
            "os": "ios",
        },
        expected_build_settings = {
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
        expected_platform_dict = {
            "arch": "arm64",
            "name": "macosx",
            "minimum_os_version": "12.1",
            "os": "macos",
        },
        expected_build_settings = {
            "MACOSX_DEPLOYMENT_TARGET": "12.1",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
