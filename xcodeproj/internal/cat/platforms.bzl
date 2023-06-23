"""Functions for processing platforms."""

_IS_SIMULATOR = {
    apple_common.platform.ios_device: False,
    apple_common.platform.ios_simulator: True,
    apple_common.platform.macos: False,
    apple_common.platform.tvos_device: False,
    apple_common.platform.tvos_simulator: True,
    apple_common.platform.watchos_device: False,
    apple_common.platform.watchos_simulator: True,
}

PLATFORM_NAME = {
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
        An opaque `struct` to be used with `platforms.to_dto`.
    """
    apple_fragment = ctx.fragments.apple
    platform = apple_fragment.single_arch_platform
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    minimum_os_version = str(
        xcode_config.minimum_os_for_platform_type(platform.platform_type),
    )

    return struct(
        arch = apple_fragment.single_arch_cpu,
        os_version = minimum_os_version,
        platform = platform,
    )

def _is_not_macos(platform):
    """Returns whether a platform is not macOS."""
    return platform.platform != apple_common.platform.macos

def _is_same_type(lhs, rhs):
    """Returns whether two platforms are the same platform type."""
    return lhs.platform.platform_type == rhs.platform.platform_type

def _is_simulator(platform):
    """Returns whether a platform is a simulator."""
    return _IS_SIMULATOR[platform.platform]

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
        platform: A value returned from `platforms.collect`.
    """
    apple_platform = platform.platform
    return "{arch}-apple-{triple_prefix}{triple_suffix}".format(
        arch = platform._arch,
        triple_prefix = _SWIFT_TRIPLE_PREFIX[apple_platform],
        triple_suffix = _TRIPLE_SUFFIX[apple_platform],
    )

def _platform_to_lldb_context_triple(platform):
    """Generates a lldb context triple for a platform.

    Args:
        platform: A value returned from `platforms.collect`.
    """
    apple_platform = platform.platform
    return "{arch}-apple-{triple_prefix}{triple_suffix}".format(
        arch = platform._arch,
        triple_prefix = _LLDB_TRIPLE_PREFIX[apple_platform],
        triple_suffix = _TRIPLE_SUFFIX[apple_platform],
    )

platforms = struct(
    collect = _collect_platform,
    is_not_macos = _is_not_macos,
    is_same_type = _is_same_type,
    is_simulator = _is_simulator,
    to_lldb_context_triple = _platform_to_lldb_context_triple,
    to_swift_triple = _platform_to_swift_triple,
)
