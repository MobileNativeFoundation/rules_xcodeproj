"""Internal API for creating and manipulating Xcode schemes."""

def _scheme(
        name,
        build_action = None,
        launch_action = None,
        profile_action = None,
        test_action = None):
    """Returns a `struct` representing an Xcode scheme.

    Args:
        name: The user-visible name for the scheme as a `string`.
        build_action: Optional. A value returned by
            `xcode_schemes.build_action`.
        launch_action: Optional. A value returned by
            `xcode_schemes.launch_action`.
        profile_action: Optional. A value returned by
            `xcode_schemes.profile_action`.
        test_action: Optional. A value returned by
            `xcode_schemes.test_action`.

    Returns:
        A `struct` representing an Xcode scheme.
    """
    return struct(
        name = name.replace("/", "_").replace(":", "_"),
        build_action = build_action,
        launch_action = launch_action,
        profile_action = profile_action,
        test_action = test_action,
    )

def _build_action(targets, pre_actions, post_actions):
    """Constructs a build action for an Xcode scheme.

    Args:
        targets: A `sequence` of `struct` values as created by
            `xcode_schemes.build_target`.
        pre_actions: A `sequence` of `struct` values as created by
            `xcode_schemes.pre_post_action`.
        post_actions: A `sequence` of `struct` values as created by
            `xcode_schemes.pre_post_action`.

    Returns:
        A `struct` representing a build action.
    """
    return struct(
        targets = targets,
        pre_actions = pre_actions,
        post_actions = post_actions,
    )

def _build_target(label, build_for = None):
    """Constructs a build target for an Xcode scheme's build action.

    Args:
        label: A target label as a `string` value.
        build_for: Optional. The settings that dictate when Xcode will build
            the target. It is a value returned by `xcode_schemes.build_for`.

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
        build_configuration,
        args = None,
        diagnostics = None,
        env = None,
        expand_variables_based_on = None,
        pre_actions = [],
        post_actions = []):
    """Constructs a test action for an Xcode scheme.

    Args:
        targets: A `sequence` of target labels as `string` values.
        build_configuration: The name of the build configuration as a `string`
            value.
        args: Optional. A `list` of `string` arguments that should be passed
            to the target when executed. If both this and `env` are `None`
            (not just empty), then the launch action's arguments will be
            inherited.
        diagnostics: Optional. A value returned by `xcode_schemes.diagnostics`.
        env: Optional. A `dict` of `string` values that will be set as
            environment variables when the target is executed. If both this
            and `args` are `None` (not just empty), then the launch action's
            environment variables will be inherited.
        expand_variables_based_on: Optional. One of the specified test target labels.
            If no value is provided, one of the test targets will be selected.
            If no expansion context is desired, use the `string` value `none`.
        pre_actions: Optional. A `sequence` of `struct` values as created by
            `xcode_schemes.pre_post_action`.
        post_actions: Optional. A `sequence` of `struct` values as created by
            `xcode_schemes.pre_post_action`.

    Returns:
        A `struct` representing a test action.
    """

    if targets == []:
        fail("At least one test target must be specified for a test action.")

    if expand_variables_based_on and expand_variables_based_on != "none":
        test_target_labels = {label: None for label in targets}
        if expand_variables_based_on not in test_target_labels:
            fail("""\
The `expand_variables_based_on` value must be `None`, the string value 'none', \
or one of the test targets.
""")

    return struct(
        targets = targets,
        build_configuration = build_configuration,
        args = args,
        diagnostics = diagnostics,
        env = env,
        expand_variables_based_on = expand_variables_based_on,
        pre_actions = pre_actions,
        post_actions = post_actions,
    )

def _launch_action(
        target,
        build_configuration,
        args = None,
        diagnostics = None,
        env = None,
        working_directory = None):
    """Constructs a launch action for an Xcode scheme.

    Args:
        target: A target label as a `string` value.
        build_configuration: The name of the build configuration as a `string`
            value.
        args: Optional. A `list` of `string` arguments that should be passed to
            the target when executed.
        diagnostics: Optional. A value returned by `xcode_schemes.diagnostics`.
        env: Optional. A `dict` of `string` values that will be set as
            environment variables when the target is executed.
        working_directory: Optional. A `string` that will be set as the custom
            working directory in the Xcode scheme's launch action.

    Returns:
        A `struct` representing a launch action.
    """
    return struct(
        target = target,
        build_configuration = build_configuration,
        args = args if args != None else [],
        diagnostics = diagnostics,
        env = env if env != None else {},
        working_directory = working_directory,
    )

def _profile_action(
        target,
        build_configuration,
        args = None,
        env = None,
        working_directory = None):
    """Constructs a launch action for an Xcode scheme.

    Args:
        target: A target label as a `string` value.
        build_configuration: The name of the build configuration as a `string`
            value.
        args: Optional. A `list` of `string` arguments that should be passed to
            the target when executed.
        env: Optional. A `dict` of `string` values that will be set as
            environment variables when the target is executed.
        working_directory: Optional. A `string` that will be set as the custom
            working directory in the Xcode scheme's launch action.

    Returns:
        A `struct` representing a profile action.
    """
    return struct(
        target = target,
        build_configuration = build_configuration,
        args = args,
        env = env,
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
    profile_action = _profile_action,
    BUILD_FOR_ALL_ENABLED = _build_for(
        running = True,
        testing = True,
        profiling = True,
        archiving = True,
        analyzing = True,
    ),
)
