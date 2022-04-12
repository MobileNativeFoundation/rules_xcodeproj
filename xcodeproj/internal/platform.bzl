"""Functions for processing platforms."""

_DEPLOYMENT_TARGET_KEY = {
    apple_common.platform_type.ios: "IPHONEOS_DEPLOYMENT_TARGET",
    apple_common.platform_type.macos: "MACOSX_DEPLOYMENT_TARGET",
    apple_common.platform_type.watchos: "WATCHOS_DEPLOYMENT_TARGET",
    apple_common.platform_type.tvos: "TVOS_DEPLOYMENT_TARGET",
}

_PLATFORM_NAME = {
    apple_common.platform.ios_device: "iphoneos",
    apple_common.platform.ios_simulator: "iphonesimulator",
    apple_common.platform.macos: "macosx",
    apple_common.platform.tvos_device: "appletvos",
    apple_common.platform.tvos_simulator: "appletvsimulator",
    apple_common.platform.watchos_device: "watchos",
    apple_common.platform.watchos_simulator: "watchsimulator",
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

    platform_dict = {
        "os": str(platform_type),
        "arch": arch,
        "minimum_os_version": minimum_os_version,
    }
    if not is_device:
        platform_dict["environment"] = "Simulator"

    build_settings[_DEPLOYMENT_TARGET_KEY[platform_type]] = (
        minimum_deployment_os_version if minimum_deployment_os_version else minimum_os_version
    )
    build_settings["SUPPORTED_PLATFORMS"] = _PLATFORM_NAME[platform]

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
