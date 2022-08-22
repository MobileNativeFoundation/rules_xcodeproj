"""Internal API for creating and manipulating Xcode schemes."""

load("@bazel_skylib//lib:sets.bzl", "sets")

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

    Returns:
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

def _build_for_value(bool_value):
    """Converts an optional `bool` value to an appropriate `build_for` setting.

    Args:
        bool_value: Optional. A `bool` value.

    Returns:
        A `string` value representing the `build_for` value to use.
    """
    if bool_value == None:
        return build_for_values.UNSPECIFIED
    elif bool_value == True:
        return build_for_values.ENABLED
    elif bool_value == False:
        return build_for_values.DISABLED
    fail("Unrecognized build_for value: {bool_value}".format(
        bool_value = bool_value,
    ))

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
        running = _build_for_value(running),
        testing = _build_for_value(testing),
        profiling = _build_for_value(profiling),
        archiving = _build_for_value(archiving),
        analyzing = _build_for_value(analyzing),
    )

def _test_action(
        targets,
        build_configuration_name,
        args = None,
        env = None,
        expand_variables_based_on = None):
    """Constructs a test action for an Xcode scheme.

    Args:
        targets: A `sequence` of target labels as `string` values.
        build_configuration_name: The name of the build configuration as a
            `string` value.
        args: Optional. A `list` of `string` arguments that should be passed to
            the target when executed.
        env: Optional. A `dict` of `string` values that will be set as
            environment variables when the target is executed.
        expand_variables_based_on: Optional. One of the specified test target labels.
            If no value is provided, one of the test targets will be selected.
            If no expansion context is desired, use the `string` value `none`.

    Returns:
        A `struct` representing a test action.
    """

    if targets == []:
        fail("At least one test target must be specified for a test action.")

    if not expand_variables_based_on:
        expand_variables_based_on = targets[0]
    elif expand_variables_based_on and expand_variables_based_on != "none":
        test_target_labels = sets.make(targets)
        if not sets.contains(test_target_labels, expand_variables_based_on):
            fail("""\
The `expand_variables_based_on` value must be 'none' or one of the test targets.
""")

    return struct(
        targets = targets,
        build_configuration_name = build_configuration_name,
        args = args if args != None else [],
        env = env if env != None else {},
        expand_variables_based_on = expand_variables_based_on,
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

    Returns:
        A `struct` representing a launch action.
    """
    return struct(
        target = target,
        build_configuration_name = build_configuration_name,
        args = args if args != None else [],
        env = env if env != None else {},
        working_directory = working_directory,
    )

build_for_values = struct(
    UNSPECIFIED = "unspecified",
    ENABLED = "enabled",
    DISABLED = "disabled",
)

xcode_schemes_internal = struct(
    scheme = _scheme,
    build_action = _build_action,
    build_target = _build_target,
    build_for = _build_for,
    build_for_values = build_for_values,
    test_action = _test_action,
    launch_action = _launch_action,
)
