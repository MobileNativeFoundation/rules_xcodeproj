def _get_resource_set_name(path, suffix):
    suffix_idx = path.find(suffix)
    if suffix_idx == -1:
        return None
    prev_delimiter_idx = path[:suffix_idx].rfind("/")
    if prev_delimiter_idx == -1:
        name_start_idx = 0
    else:
        name_start_idx = prev_delimiter_idx + 1
    return path[name_start_idx:suffix_idx]

_RESOURCE_SET_SUFFIXES = [".appiconset", ".brandassets"]

def _get_app_icon_info(ctx, automatic_target_info):
    """Attempts to find the applicaiton icon name.

    Args:
        ctx: The aspect context.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.

    Returns:
        The application icon name, if found. Otherwise, None.
    """
    if not automatic_target_info.app_icons:
        return None

    app_icons = getattr(ctx.rule.attr, automatic_target_info.app_icons, None)
    if not app_icons:
        return None

    resource_files = [
        file
        for target in app_icons
        for file in target.files.to_list()
    ]
    for file in resource_files:
        for suffix in _RESOURCE_SET_SUFFIXES:
            set_name = _get_resource_set_name(file.short_path, suffix)
            if not set_name:
                continue
            return _create(
                set_name = set_name,
                # TODO(chuck): FIX ME!
                default_icon_name = None,
            )

    return None

def _create(set_name, default_icon_name):
    return struct(
        set_name = set_name,
        default_icon_name = default_icon_name,
    )

app_icons = struct(
    create = _create,
    get_app_icon_info = _get_app_icon_info,
)
