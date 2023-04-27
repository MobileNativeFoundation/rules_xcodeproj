"""Functions for calculating configuration."""

def calculate_configuration(*, bin_dir_path):
    """Generates a configuration identifier for a target.

    `ConfiguredTarget.getConfigurationKey()` isn't exposed to Starlark, so we
    are using the output directory as a proxy.

    Args:
        bin_dir_path: `ctx.bin_dir.path`.

    Returns:
        A string that uniquely identifies the configuration of a target.
    """
    path_components = bin_dir_path.split("/")
    if len(path_components) > 2:
        return path_components[1]
    return ""
