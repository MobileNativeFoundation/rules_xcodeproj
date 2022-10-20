"""Functions for processing platforms."""

_PLATFORM_NAME = {
    apple_common.platform.ios_device: "iphoneos",
    apple_common.platform.ios_simulator: "iphonesimulator",
    apple_common.platform.macos: "macosx",
    apple_common.platform.tvos_device: "appletvos",
    apple_common.platform.tvos_simulator: "appletvsimulator",
    apple_common.platform.watchos_device: "watchos",
    apple_common.platform.watchos_simulator: "watchsimulator",
}

def _collect_platform(*, ctx):
    """Collects information about a target's platform.

    Args:
        ctx: The aspect context.

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
        _arch = apple_fragment.single_arch_cpu,
        _os_version = minimum_os_version,
        _platform = platform,
    )

def _is_same_type(lhs, rhs):
    """Returns whether two platforms are the same platform type."""
    return lhs._platform.platform_type == rhs._platform.platform_type

def _platform_to_dto(platform):
    """Generates a target DTO value for a platform.

    Args:
        platform: A value returned from `platform_info.collect`.
    """
    apple_platform = platform._platform
    platform_type = apple_platform.platform_type

    dto = {
        "os": str(platform_type),
        "variant": _PLATFORM_NAME[apple_platform],
        "arch": platform._arch,
        "minimum_os_version": platform._os_version,
    }

    return dto

platform_info = struct(
    collect = _collect_platform,
    is_same_type = _is_same_type,
    to_dto = _platform_to_dto,
)
