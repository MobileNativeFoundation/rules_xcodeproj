""" Functions for calculating configuration."""

def calculate_configuration(*, bin_dir_path):
    """Calculates a configuration string from `ctx.bin_dir`.

    Args:
        bin_dir_path: `ctx.bin_dir.path`.

    Returns:
        A string that represents a configuration.
    """
    path_components = bin_dir_path.split("/")
    if len(path_components) > 2:
        return path_components[1]
    return ""

def get_configuration(ctx):
    """Generates a configuration identifier for a target.

    `ConfiguredTarget.getConfigurationKey()` isn't exposed to Starlark, so we
    are using the output directory as a proxy.

    Args:
        ctx: The aspect context.

    Returns:
        A string that uniquely identifies the configuration of a target.
    """
    return calculate_configuration(bin_dir_path = ctx.bin_dir.path)
