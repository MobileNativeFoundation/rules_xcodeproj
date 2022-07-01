"""API for defining custom Xcode schemes"""

load("@bazel_skylib//lib:sets.bzl", "sets")
load(":bazel_labels.bzl", "bazel_labels")

# TODO: Consider switching loading_phase to injecting the module to use for
# bazel_labels.

def _scheme(
        name,
        build_action = None,
        test_action = None,
        launch_action = None):
    """Returns a `struct` representing an Xcode scheme.

    Args:
        name: The user-visible name for the scheme as a `string`.
        build_action: Optional. A `struct` as returned by
            `xcode_schemes.build_action`.
        test_action: Optional. A `struct` as returned by
            `xcode_schemes.test_action`.
        launch_action: Optional. A `struct` as returned by
            `xcode_schemes.launch_action`.

    Returns:
        A `struct` representing an Xcode scheme.
    """
    return struct(
        name = name,
        build_action = build_action,
        test_action = test_action,
        launch_action = launch_action,
    )

def _build_action(targets, loading_phase = True):
    """Constructs a build action for an Xcode scheme.

    Args:
        targets: A `sequence` of target labels as `string` values.
        load_phase: Optional. A `bool` that indicates whether the function is
            being called from Bazel's loading phase. Some native functionality
            is only available during the loading phase.

    Return:
        A `struct` representing a build action.
    """
    return struct(
        targets = [
            bazel_labels.normalize(t, loading_phase = loading_phase)
            for t in targets
        ],
    )

def _test_action(targets, loading_phase = True):
    """Constructs a test action for an Xcode scheme.

    Args:
        targets: A `sequence` of target labels as `string` values.
        load_phase: Optional. A `bool` that indicates whether the function is
            being called from Bazel's loading phase. Some native functionality
            is only available during the loading phase.

    Return:
        A `struct` representing a test action.
    """
    return struct(
        targets = [
            bazel_labels.normalize(t, loading_phase = loading_phase)
            for t in targets
        ],
    )

def _launch_action(
        target,
        args = None,
        env = None,
        working_directory = None,
        loading_phase = True):
    """Constructs a launch action for an Xcode scheme.

    Args:
        target: A target label as a `string` value.
        args: Optional. A `list` of `string` arguments that should be passed to
            the target when executed.
        env: Optional. A `dict` of `string` values that will be set as
            environment variables when the target is executed.
        working_directory: Optional. A `string` that will be set as the custom
            working directory in the Xcode scheme's launch action.
        load_phase: Optional. A `bool` that indicates whether the function is
            being called from Bazel's loading phase. Some native functionality
            is only available during the loading phase.

    Return:
        A `struct` representing a launch action.
    """
    return struct(
        target = bazel_labels.normalize(target, loading_phase = loading_phase),
        args = args,
        env = env,
        working_directory = working_directory,
    )

def _collect_top_level_targets_from_a_scheme(scheme):
    results = sets.make()
    if scheme.test_action != None:
        for target in scheme.test_action.targets:
            sets.insert(results, target)
    if scheme.launch_action != None:
        sets.insert(results, scheme.launch_action.target)
    return results

def _collect_top_level_targets(schemes):
    """Collect the top-level targets from a `sequence` of schemes.

    Args:
        schemes: A `sequence` of `struct` values as returned by
            `xcode_schemes.scheme`.

    Returns:
        A  `set` of `string` values representing Bazel labels that are top-level
        targets.
    """
    results = sets.make()
    for scheme in schemes:
        results = sets.union(
            results,
            _collect_top_level_targets_from_a_scheme(scheme),
        )
    return results

xcode_schemes = struct(
    scheme = _scheme,
    build_action = _build_action,
    test_action = _test_action,
    launch_action = _launch_action,
    collect_top_level_targets = _collect_top_level_targets,
)
