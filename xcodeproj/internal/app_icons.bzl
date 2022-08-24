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

def _find_resource_set(ctx, automatic_target_info):
    if not automatic_target_info.app_icons:
        return None, None

    app_icons = getattr(ctx.rule.attr, automatic_target_info.app_icons, None)
    if not app_icons:
        return None, None

    resource_files = [
        file
        for target in app_icons
        for file in target.files.to_list()
    ]
    for file in resource_files:
        for suffix in _RESOURCE_SET_SUFFIXES:
            set_name, set_path = _get_resource_set_name(file.short_path, suffix)
            if not set_name:
                continue
            return set_name, set_path

    return None, None

def _get_app_icon_info(ctx, automatic_target_info):
    """Attempts to find the applicaiton icon name.

    Args:
        ctx: The aspect context.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.

    Returns:
        The application icon name, if found. Otherwise, None.
    """
    set_name, set_path = _find_resource_set(ctx, automatic_target_info)
    if not set_name:
        return None

    return _create(
        set_name = set_name,
        set_path = set_path,
        # TODO(chuck): FIX ME!
        default_icon_path = None,
    )

def _create(set_name, set_path, default_icon_path):
    return struct(
        set_name = set_name,
        set_path = set_path,
        default_icon_path = default_icon_path,
    )

app_icons = struct(
    create = _create,
    get_app_icon_info = _get_app_icon_info,
)
