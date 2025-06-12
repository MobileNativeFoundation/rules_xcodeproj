"""Module for retrieving application icon information"""

load("@bazel_skylib//lib:paths.bzl", "paths")

def _get_resource_set_name(path, suffix):
    suffix_idx = path.find(suffix)
    if suffix_idx == -1:
        return None, None
    suffix_end_idx = suffix_idx + len(suffix)
    prev_delimiter_idx = path[:suffix_idx].rfind("/")
    if prev_delimiter_idx == -1:
        name_start_idx = 0
    else:
        name_start_idx = prev_delimiter_idx + 1
    return path[name_start_idx:suffix_idx], path[:suffix_end_idx]

_RESOURCE_SET_SUFFIXES = [".appiconset", ".brandassets"]

def _find_resource_set(app_icon_files):
    for file in app_icon_files:
        for suffix in _RESOURCE_SET_SUFFIXES:
            set_name, set_path = _get_resource_set_name(file.short_path, suffix)
            if not set_name:
                continue
            return set_name, set_path

    return None, None

_IMAGE_EXTS = {
    ".jpeg": None,
    ".jpg": None,
    ".png": None,
}

def _find_default_icon_path(set_path, app_icon_files):
    # GH949: Update the file selection logic to use the contents of the resource
    # set's `Contents.json`.
    for file in app_icon_files:
        file_path = file.short_path
        if not file_path.startswith(set_path):
            continue
        _, ext = paths.split_extension(file_path)
        if ext not in _IMAGE_EXTS:
            continue
        return file_path

    return None

def _get_app_icon_info(automatic_target_info, rule_attr):
    """Attempts to find the application icon name.

    Args:
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        rule_attr: `ctx.rule.attr`.

    Returns:
        The application icon name, if found. Otherwise, `None`.
    """
    if not automatic_target_info.app_icons:
        return None

    app_icons = getattr(rule_attr, automatic_target_info.app_icons, None)
    if not app_icons:
        return None

    app_icon_files = [
        file
        for target in app_icons
        for file in target.files.to_list()
    ]

    set_name, set_path = _find_resource_set(app_icon_files)
    if not set_name:
        return None

    default_icon_path = _find_default_icon_path(set_path, app_icon_files)

    return _create(
        set_name = set_name,
        set_path = set_path,
        default_icon_path = default_icon_path,
    )

def _create(set_name, set_path, default_icon_path):
    """Creates a `struct` representing information about a target's application \
    icons.

    Args:
      set_name: The name of the resource set as a `string`.
      set_path: The path of the resource set as a `string`.
      default_icon_path: If a default icon should be identified, the path to
          the icon file will be set as a `string`.

    Returns:
        A `struct` representing application icon information.
    """
    return struct(
        set_name = set_name,
        set_path = set_path,
        default_icon_path = default_icon_path,
    )

app_icons = struct(
    create = _create,
    get_info = _get_app_icon_info,
)
