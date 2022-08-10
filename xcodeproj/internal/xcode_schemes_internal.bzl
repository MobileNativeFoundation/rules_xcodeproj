"""Internal API for creating and manipulating Xcode schemes."""

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

def _build_action(targets):
    """Constructs a build action for an Xcode scheme.

    Args:
        targets: A `sequence` of `struct` values as created by
            `xcode_schemes.build_target`.

    Return:
        A `struct` representing a build action.
    """
    return struct(
        targets = targets,
    )

def _build_target(label, build_for = None):
    """Constructs a build target for an Xcode scheme's build action.

    Args:
        label: A target label as a `string` value.
        build_for: Optional. The settings that dictate when Xcode will build
            the target. It is a `struct` as returned by
            `xcode_schemes.build_for`.

    Returns:
        A `struct` representing a build target.
    """
    return struct(
        label = label,
        build_for = build_for,
    )

def _build_for(
        running = None,
        testing = None,
        profiling = None,
        archiving = None,
        analyzing = None):
    """Construct a `struct` representing the settings that dictate when Xcode \
    will build a target.

    Args:
        running: Optional. A `bool` specifying whether to build for the running
            phase.
        testing: Optional. A `bool` specifying whether to build for the testing
            phase.
        profiling: Optional. A `bool` specifying whether to build for the
            profiling phase.
        archiving: Optional. A `bool` specifying whether to build for the
            archiving phase.
        analyzing: Optional. A `bool` specifying whether to build for the
            analyzing phase.

    Returns:
        A `struct`.
    """
    return struct(
        running = running,
        testing = testing,
        profiling = profiling,
        archiving = archiving,
        analyzing = analyzing,
    )

def _test_action(targets, build_configuration_name):
    """Constructs a test action for an Xcode scheme.

    Args:
        targets: A `sequence` of target labels as `string` values.
        build_configuration_name: The name of the build configuration as a
            `string` value.

    Return:
        A `struct` representing a test action.
    """
    return struct(
        targets = targets,
        build_configuration_name = build_configuration_name,
    )

def _launch_action(
        target,
        build_configuration_name,
        args = None,
        env = None,
        working_directory = None):
    """Constructs a launch action for an Xcode scheme.

    Args:
        target: A target label as a `string` value.
        build_configuration_name: The name of the build configuration as a
            `string` value.
        args: Optional. A `list` of `string` arguments that should be passed to
            the target when executed.
        env: Optional. A `dict` of `string` values that will be set as
            environment variables when the target is executed.
        working_directory: Optional. A `string` that will be set as the custom
            working directory in the Xcode scheme's launch action.

    Return:
        A `struct` representing a launch action.
    """
    return struct(
        target = target,
        build_configuration_name = build_configuration_name,
        args = args if args != None else [],
        env = env if env != None else {},
        working_directory = working_directory,
    )

xcode_schemes_internal = struct(
    scheme = _scheme,
    build_action = _build_action,
    build_target = _build_target,
    build_for = _build_for,
    test_action = _test_action,
    launch_action = _launch_action,
)
