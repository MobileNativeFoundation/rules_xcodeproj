"""Functions for handling Xcode build settings."""

def set_if_true(build_settings, key, value):
    """Sets `build_settings[key]` to `value` if it doesn't evaluate to `False`.

    This is useful for setting build settings that are lists, but only when we
    have a value to set.
    """
    if value:
        build_settings[key] = value
