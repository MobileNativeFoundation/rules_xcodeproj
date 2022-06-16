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

def _collect(*, ctx, minimum_deployment_os_version):
    """Collects information about a target's platform.

    Args:
        ctx: The aspect context.
        minimum_deployment_os_version: The minimum deployment OS version for the
            target.

    Returns:
        An opaque `struct` to be used with `platform_info.to_dto`.
    """
    apple_fragment = ctx.fragments.apple
    platform = apple_fragment.single_arch_platform
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    minimum_os_version = str(
        xcode_config.minimum_os_for_platform_type(platform.platform_type),
    )

    return struct(
        _platform = platform,
        _arch = apple_fragment.single_arch_cpu,
        _minimum_os_version = minimum_os_version,
        _minimum_deployment_os_version = minimum_deployment_os_version,
    )

def _to_dto(platform, *, build_settings):
    """Generates a target DTO value for a platform.

    Args:
        platform: A value returned from `platform_info.collect`.
        build_settings: A mutable `dict` that will be updated with Xcode build
            settings.
    """
    arch = platform._arch
    os_version = platform._minimum_os_version
    deployment_os_version = platform._minimum_deployment_os_version
    platform = platform._platform

    platform_type = platform.platform_type
    is_device = platform.is_device

    dto = {
        "name": _PLATFORM_NAME[platform],
        "os": str(platform_type),
        "arch": arch,
        "minimum_os_version": os_version,
    }
    if not is_device:
        dto["environment"] = "Simulator"

    build_settings[_DEPLOYMENT_TARGET_KEY[platform_type]] = (
        deployment_os_version if deployment_os_version else os_version
    )

    return dto

platform_info = struct(
    collect = _collect,
    to_dto = _to_dto,
)
