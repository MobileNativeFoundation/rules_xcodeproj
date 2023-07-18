"""Testing utility functions."""

_PLATFORM_NAME = {
    "IOS_DEVICE": "iphoneos",
    "IOS_SIMULATOR": "iphonesimulator",
    "MACOS": "macosx",
    "TVOS_DEVICE": "appletvos",
    "TVOS_SIMULATOR": "appletvsimulator",
    "WATCHOS_DEVICE": "watchos",
    "WATCHOS_SIMULATOR": "watchsimulator",
}

def mock_apple_platform_to_platform_name(platform):
    return _PLATFORM_NAME[platform]

def _stringify_dict_value(value):
    if type(value) == "tuple":
        value = list(value)
    return str(value)

def stringify_dict(dict):
    """Converts the values of a dictionary to strings."""
    return {k: _stringify_dict_value(v) for k, v in dict.items()}
