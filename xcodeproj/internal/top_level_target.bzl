"""Functions for specifying top-level targets to use with the `xcodeproj`
macro."""

load("@bazel_skylib//lib:sets.bzl", "sets")

_VALID_TARGET_ENVIRONMENTS = sets.make(["device", "simulator"])

def top_level_target(label, *, extra_files = None, target_environments = ["simulator"]):
    """Constructs a top-level target for use in `xcodeproj.top_level_targets`.

    Args:
        label: A `Label` or label-like string for the target.
        extra_files: Optional. A `list` of extra files to be added to the project.
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

    target_environments = sets.make(target_environments)

    invalid_target_environments = sets.to_list(
        sets.difference(target_environments, _VALID_TARGET_ENVIRONMENTS),
    )
    if invalid_target_environments:
        fail("`target_environments` contains invalid elements: {}".format(
            invalid_target_environments,
        ))

    return struct(
        label = label,
        extra_files = extra_files,
        target_environments = target_environments,
    )
