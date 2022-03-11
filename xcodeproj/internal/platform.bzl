"""Functions for processing platforms."""

_DEPLOYMENT_TARGET_KEY = {
    apple_common.platform_type.ios: "IPHONEOS_DEPLOYMENT_TARGET",
    apple_common.platform_type.macos: "MACOSX_DEPLOYMENT_TARGET",
    apple_common.platform_type.tvos: "TVOS_DEPLOYMENT_TARGET",
    apple_common.platform_type.watchos: "WATCHOS_DEPLOYMENT_TARGET",
}

_PRETTY_OS = {
    apple_common.platform_type.ios: "iOS",
    apple_common.platform_type.macos: "macOS",
    apple_common.platform_type.tvos: "tvOS",
    apple_common.platform_type.watchos: "watchOS",
}

_SDK_ROOT = {
    apple_common.platform_type.ios: "iphoneos",
    apple_common.platform_type.macos: "macosx",
    apple_common.platform_type.tvos: "appletvos",
    apple_common.platform_type.watchos: "watchos",
}

def _generate_platform_information(
        *,
        platform,
        arch,
        minimum_os_version,
        minimum_deployment_os_version,
        build_settings):
    """Generates the platform information for a given platform.

    Args:
        platform: An `apple_platform`. See
            https://bazel.build/rules/lib/apple_platform.
        arch: A cpu architecture string. See
            https://bazel.build/rules/lib/apple#single_arch_cpu.
        minimum_os_version: A string of the minimum OS version. See
            https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-ios.md#ios_application-minimum_os_version.
        minimum_deployment_os_version: A string of the minimum deployment OS
            version. See https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-ios.md#ios_application-minimum_deployment_os_version.
        build_settings: A mutable `dict` that will be updated with Xcode build
            settings.

    Returns:
        A `dict` of platform information.
    """
    platform_type = platform.platform_type
    is_device = platform.is_device
    if is_device and platform_type != apple_common.platform_type.macos:
        fail("Currently you must build for simulator when generating a project")

    platform_dict = {
        "os": _PRETTY_OS[platform_type],
        "arch": arch,
        "minimum_os_version": minimum_os_version,
    }
    if not is_device:
        platform_dict["environment"] = "Simulator"

    build_settings["SDKROOT"] = _SDK_ROOT[platform_type]
    build_settings[_DEPLOYMENT_TARGET_KEY[platform_type]] = (
        minimum_deployment_os_version if minimum_deployment_os_version else minimum_os_version
    )

    return platform_dict

# API

def process_platform(*, ctx, minimum_deployment_os_version, build_settings):
    """Generates information about a target's platform.

    Args:
        ctx: The aspect context.
        minimum_deployment_os_version: The minimum deployment OS version for the
            target.
        build_settings: A mutable `dict` that will be updated with Xcode build
            settings.

    Returns:
        A `dict` of platform information.
    """
    apple_fragment = ctx.fragments.apple
    platform = apple_fragment.single_arch_platform
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    minimum_os_version = str(
        xcode_config.minimum_os_for_platform_type(platform.platform_type),
    )

    return _generate_platform_information(
        platform = platform,
        arch = apple_fragment.single_arch_cpu,
        minimum_os_version = minimum_os_version,
        minimum_deployment_os_version = minimum_deployment_os_version,
        build_settings = build_settings,
    )

# These functions are exposed only for access in unit tests.
testable = struct(
    generate_platform_information = _generate_platform_information,
)
