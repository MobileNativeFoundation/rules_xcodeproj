"""Tests for platform processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:utils.bzl", "stringify_dict")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:platforms.bzl", "platforms")

def _platforms_to_dto_test_impl(ctx):
    env = unittest.begin(ctx)

    platform = struct(
        _arch = ctx.attr.arch,
        _os_version = ctx.attr.minimum_os_version,
        _platform = getattr(apple_common.platform, ctx.attr.platform_key),
    )
    dto = platforms.to_dto(platform)
    string_platform = stringify_dict(dto)

    asserts.equals(
        env,
        ctx.attr.expected_platform_dict,
        string_platform,
        "platform",
    )

    return unittest.end(env)

platforms_to_dto_test = unittest.make(
    impl = _platforms_to_dto_test_impl,
    attrs = {
        "arch": attr.string(mandatory = True),
        "expected_platform_dict": attr.string_dict(mandatory = True),
        "minimum_os_version": attr.string(mandatory = True),
        "platform_key": attr.string(mandatory = True),
    },
)

def platforms_to_dto_test_suite(name):
    """Test suite for `platforms.to_dto`.

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
            expected_platform_dict):
        test_names.append(name)
        platforms_to_dto_test(
            name = name,
            platform_key = platform_key,
            arch = arch,
            minimum_os_version = minimum_os_version,
            expected_platform_dict = expected_platform_dict,
            timeout = "short",
        )

    # Minimum OS version

    _add_test(
        name = "{}_minimum_os_version".format(name),
        platform_key = "tvos_device",
        arch = "wild",
        minimum_os_version = "12.0",
        expected_platform_dict = {
            "a": "wild",
            "m": "12.0",
            "v": "appletvos",
        },
    )

    # Environment

    _add_test(
        name = "{}_no_environment".format(name),
        platform_key = "macos",
        arch = "arm64",
        minimum_os_version = "12.1",
        expected_platform_dict = {
            "a": "arm64",
            "m": "12.1",
            "v": "macosx",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
