"""Functions for specifying top-level targets to use with the `xcodeproj`
macro."""

_VALID_TARGET_ENVIRONMENTS = {
    "device": None,
    "simulator": None,
}

def top_level_target(label, *, target_environments = ["simulator"]):
    """Constructs a top-level target for use in `xcodeproj.top_level_targets`.

    Args:
        label: A `Label` or label-like string for the target.
        target_environments: Optional. A `list` of target environment strings
            (see `@build_bazel_apple_support//constraints:target_environment`;
            `"catalyst"` is not currently supported). The target will be
            configured for each environment.

            If multiple environments are specified, then a single combined Xcode
            target will be created if possible. If the configured targets are
            the same for each environment (e.g. macOS for
            `["device", "simulator"]`), they will appear as separate but similar
            Xcode targets. If no environments are specified, the `"simulator"`
            environment will be used.

    Returns:
        A `struct` containing fields for the provided arguments.
    """
    if not target_environments:
        target_environments = ["simulator"]

    target_environments = {e: None for e in target_environments}

    invalid_target_environments = [
        env
        for env in target_environments
        if env not in _VALID_TARGET_ENVIRONMENTS
    ]
    if invalid_target_environments:
        fail("`target_environments` contains invalid elements: {}".format(
            invalid_target_environments,
        ))

    return struct(
        label = label,
        target_environments = target_environments,
    )

def top_level_targets(labels, *, target_environments = ["simulator"]):
    """Constructs a list of top-level target for use in \
    `xcodeproj.top_level_targets`.

    Args:
        labels: A `list` of `Label` or label-like string for the targets.
        target_environments: Optional. See
            [`top_level_target.target_environments`](#top_level_target-target_environments).

    Returns:
        A `list` of values returned from `top_level_target`.
    """
    return [
        top_level_target(label, target_environments = target_environments)
        for label in labels
    ]
