"""Functions for calculating configuration."""

load("@bazel_features//:features.bzl", "bazel_features")

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

def is_exec_config(ctx):
    """Determines whether the current configuration is an exec configuration.

    Args:
        ctx: The rule or aspect context.

    Returns:
        Whether the current configuration is an exec configuration.
    """

    # TODO: Remove once we drop 9.x
    if bazel_features.rules.is_tool_configuration_public and ctx.configuration.is_tool_configuration():
        return True
    elif ctx.bin_dir.path.endswith("-exec/bin"):  # NOTE: 9.0.0 or <8.7.0 with --experimental_platform_in_output_dir
        return True
    elif "-exec-" in ctx.bin_dir.path:
        return True

    return False
