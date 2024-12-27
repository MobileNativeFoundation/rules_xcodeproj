"""Module for dealing with Apple platform information."""

# TODO: Remove this once we drop 7.x
def _legacy_apple_platform_starlark_name(platform):
    return platform

def _modern_apple_platform_starlark_name(platform):
    return platform.name

_apple_platform_starlark_name = _modern_apple_platform_starlark_name if hasattr(apple_common.platform.ios_device, "name") else _legacy_apple_platform_starlark_name

_IS_SIMULATOR = {
    _apple_platform_starlark_name(apple_common.platform.ios_device): False,
    _apple_platform_starlark_name(apple_common.platform.ios_simulator): True,
    _apple_platform_starlark_name(apple_common.platform.macos): False,
    _apple_platform_starlark_name(apple_common.platform.tvos_device): False,
    _apple_platform_starlark_name(apple_common.platform.tvos_simulator): True,
    _apple_platform_starlark_name(apple_common.platform.visionos_device): False,
    _apple_platform_starlark_name(apple_common.platform.visionos_simulator): True,
    _apple_platform_starlark_name(apple_common.platform.watchos_device): False,
    _apple_platform_starlark_name(apple_common.platform.watchos_simulator): True,
}

_LLDB_TRIPLE_PREFIX = {
    _apple_platform_starlark_name(apple_common.platform.ios_device): "ios",
    _apple_platform_starlark_name(apple_common.platform.ios_simulator): "ios",
    _apple_platform_starlark_name(apple_common.platform.macos): "macosx",
    _apple_platform_starlark_name(apple_common.platform.tvos_device): "tvos",
    _apple_platform_starlark_name(apple_common.platform.tvos_simulator): "tvos",
    _apple_platform_starlark_name(apple_common.platform.visionos_device): "xros",
    _apple_platform_starlark_name(apple_common.platform.visionos_simulator): "xros",
    _apple_platform_starlark_name(apple_common.platform.watchos_device): "watchos",
    _apple_platform_starlark_name(apple_common.platform.watchos_simulator): "watchos",
}

_PLATFORM_NAME = {
    _apple_platform_starlark_name(apple_common.platform.ios_device): "iphoneos",
    _apple_platform_starlark_name(apple_common.platform.ios_simulator): "iphonesimulator",
    _apple_platform_starlark_name(apple_common.platform.macos): "macosx",
    _apple_platform_starlark_name(apple_common.platform.tvos_device): "appletvos",
    _apple_platform_starlark_name(apple_common.platform.tvos_simulator): "appletvsimulator",
    _apple_platform_starlark_name(apple_common.platform.visionos_device): "xros",
    _apple_platform_starlark_name(apple_common.platform.visionos_simulator): "xrsimulator",
    _apple_platform_starlark_name(apple_common.platform.watchos_device): "watchos",
    _apple_platform_starlark_name(apple_common.platform.watchos_simulator): "watchsimulator",
}

_SWIFT_TRIPLE_PREFIX = {
    _apple_platform_starlark_name(apple_common.platform.ios_device): "ios",
    _apple_platform_starlark_name(apple_common.platform.ios_simulator): "ios",
    _apple_platform_starlark_name(apple_common.platform.macos): "macos",
    _apple_platform_starlark_name(apple_common.platform.tvos_device): "tvos",
    _apple_platform_starlark_name(apple_common.platform.tvos_simulator): "tvos",
    _apple_platform_starlark_name(apple_common.platform.visionos_device): "xros",
    _apple_platform_starlark_name(apple_common.platform.visionos_simulator): "xros",
    _apple_platform_starlark_name(apple_common.platform.watchos_device): "watchos",
    _apple_platform_starlark_name(apple_common.platform.watchos_simulator): "watchos",
}

_TRIPLE_SUFFIX = {
    _apple_platform_starlark_name(apple_common.platform.ios_device): "",
    _apple_platform_starlark_name(apple_common.platform.ios_simulator): "-simulator",
    _apple_platform_starlark_name(apple_common.platform.macos): "",
    _apple_platform_starlark_name(apple_common.platform.tvos_device): "",
    _apple_platform_starlark_name(apple_common.platform.tvos_simulator): "-simulator",
    _apple_platform_starlark_name(apple_common.platform.visionos_device): "",
    _apple_platform_starlark_name(apple_common.platform.visionos_simulator): "-simulator",
    _apple_platform_starlark_name(apple_common.platform.watchos_device): "",
    _apple_platform_starlark_name(apple_common.platform.watchos_simulator): "-simulator",
}

def _apple_platform_to_platform_name(apple_platform):
    """Returns the name of a platform.

    Args:
        apple_platform: A value from `apple_common.platform`.
    """
    return _PLATFORM_NAME[_apple_platform_starlark_name(apple_platform)]

def _collect_platform(*, ctx):
    """Collects information about a target's platform.

    Args:
        ctx: The aspect context.

    Returns:
        An opaque `struct` to be used with `platforms.to_dto`.
    """
    apple_fragment = ctx.fragments.apple
    apple_platform = apple_fragment.single_arch_platform
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    minimum_os_version = str(
        xcode_config.minimum_os_for_platform_type(apple_platform.platform_type),
    )

    return struct(
        apple_platform = apple_platform,
        arch = apple_fragment.single_arch_cpu,
        os_version = minimum_os_version,
    )

def _is_not_macos(platform):
    """Returns whether a platform is not macOS."""
    return platform.apple_platform != apple_common.platform.macos

def _is_platform_type(platform, platform_type):
    """Returns whether a platform is of a given type.

    Args:
        platform: A value from `platforms.collect`.
        platform_type: A value from `apple_common.platform`.
    """
    return platform.apple_platform.platform_type == platform_type

def _is_same_type(lhs, rhs):
    """Returns whether two platforms are the same platform type."""
    return lhs.apple_platform.platform_type == rhs.apple_platform.platform_type

def _is_simulator(platform):
    """Returns whether a platform is a simulator."""
    return _IS_SIMULATOR[platform.apple_platform]

def _platform_to_dto(platform):
    """Generates a target DTO value for a platform.

    Args:
        platform: A value from `platforms.collect`.
    """
    dto = {
        "a": platform.arch,
        "m": platform.os_version,
        "v": _apple_platform_to_platform_name(platform.apple_platform),
    }

    return dto

def _platform_to_swift_triple(platform):
    """Generates a Swift triple for a platform.

    Args:
        platform: A value from `platforms.collect`.
    """
    apple_platform = _apple_platform_starlark_name(platform.apple_platform)

    return "{arch}-apple-{triple_prefix}{triple_suffix}".format(
        arch = platform.arch,
        triple_prefix = _SWIFT_TRIPLE_PREFIX[apple_platform],
        triple_suffix = _TRIPLE_SUFFIX[apple_platform],
    )

def _platform_to_lldb_context_triple(platform):
    """Generates a lldb context triple for a platform.

    Args:
        platform: A value from `platforms.collect`.
    """
    apple_platform = _apple_platform_starlark_name(platform.apple_platform)

    return "{arch}-apple-{triple_prefix}{triple_suffix}".format(
        arch = platform.arch,
        triple_prefix = _LLDB_TRIPLE_PREFIX[apple_platform],
        triple_suffix = _TRIPLE_SUFFIX[apple_platform],
    )

platforms = struct(
    apple_platform_to_platform_name = _apple_platform_to_platform_name,
    collect = _collect_platform,
    is_not_macos = _is_not_macos,
    is_platform_type = _is_platform_type,
    is_same_type = _is_same_type,
    is_simulator = _is_simulator,
    to_dto = _platform_to_dto,
    to_lldb_context_triple = _platform_to_lldb_context_triple,
    to_swift_triple = _platform_to_swift_triple,
)
