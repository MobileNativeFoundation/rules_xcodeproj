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

def _is_platform_type(platform, platform_type):
    """Returns whether a platform is of a given type.

    Args:
        platform: A value returned from `platform_info.collect`.
        platform_type: A value from `apple_common.platform`.
    """
    return platform._platform.platform_type == platform_type

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
        "o": str(platform_type),
        "v": _PLATFORM_NAME[apple_platform],
        "a": platform._arch,
        "m": platform._os_version,
    }

    return dto

_LLDB_TRIPLE_PREFIX = {
    apple_common.platform.ios_device: "ios",
    apple_common.platform.ios_simulator: "ios",
    apple_common.platform.macos: "macosx",
    apple_common.platform.tvos_device: "tvos",
    apple_common.platform.tvos_simulator: "tvos",
    apple_common.platform.watchos_device: "watchos",
    apple_common.platform.watchos_simulator: "watchos",
}

_SWIFT_TRIPLE_PREFIX = {
    apple_common.platform.ios_device: "ios",
    apple_common.platform.ios_simulator: "ios",
    apple_common.platform.macos: "macos",
    apple_common.platform.tvos_device: "tvos",
    apple_common.platform.tvos_simulator: "tvos",
    apple_common.platform.watchos_device: "watchos",
    apple_common.platform.watchos_simulator: "watchos",
}

_TRIPLE_SUFFIX = {
    apple_common.platform.ios_device: "",
    apple_common.platform.ios_simulator: "-simulator",
    apple_common.platform.macos: "",
    apple_common.platform.tvos_device: "",
    apple_common.platform.tvos_simulator: "-simulator",
    apple_common.platform.watchos_device: "",
    apple_common.platform.watchos_simulator: "-simulator",
}

def _platform_to_swift_triple(platform):
    """Generates a Swift triple for a platform.

    Args:
        platform: A value returned from `platform_info.collect`.
    """
    return "{arch}-apple-{triple_prefix}{triple_suffix}".format(
        arch = platform._arch,
        triple_prefix = _SWIFT_TRIPLE_PREFIX[platform._platform],
        triple_suffix = _TRIPLE_SUFFIX[platform._platform],
    )

def _platform_to_lldb_context_triple(platform):
    """Generates a lldb context triple for a platform.

    Args:
        platform: A value returned from `platform_info.collect`.
    """
    return "{arch}-apple-{triple_prefix}{triple_suffix}".format(
        arch = platform._arch,
        triple_prefix = _LLDB_TRIPLE_PREFIX[platform._platform],
        triple_suffix = _TRIPLE_SUFFIX[platform._platform],
    )

platform_info = struct(
    collect = _collect_platform,
    is_platform_type = _is_platform_type,
    is_same_type = _is_same_type,
    to_dto = _platform_to_dto,
    to_lldb_context_triple = _platform_to_lldb_context_triple,
    to_swift_triple = _platform_to_swift_triple,
)
