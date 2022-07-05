"""Internal API for creating and manipulating Xcode schemes"""

load(":target_id.bzl", "get_id")

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

# def _copy_scheme(
#         scheme,
#         name = None,
#         build_action = None,
#         test_action = None,
#         launch_action = None):
#     if scheme == None:
#         return None
#     return _scheme(
#         name = name if name != None else scheme.name,
#         build_action = build_action if build_action != None else scheme.build_action,
#         test_action = test_action if test_action != None else scheme.test_action,
#         launch_action = launch_action if launch_action != None else scheme.launch_action,
#     )

def _build_action(targets):
    """Constructs a build action for an Xcode scheme.

    Args:
        targets: A `sequence` of target labels as `string` values.

    Return:
        A `struct` representing a build action.
    """
    return struct(
        targets = targets,
    )

# def _copy_build_action(build_action, targets = None):
#     if build_action == None:
#         return None
#     return _build_action(
#         targets = targets if target != None else build_action.targets,
#     )

def _test_action(targets):
    """Constructs a test action for an Xcode scheme.

    Args:
        targets: A `sequence` of target labels as `string` values.

    Return:
        A `struct` representing a test action.
    """
    return struct(
        targets = targets,
    )

# def _copy_test_action(test_action, targets = None):
#     if test_action == None:
#         return None
#     return _test_action(
#         targets = targets if target != None else test_action.targets,
#     )

def _launch_action(
        target,
        args = None,
        env = None,
        working_directory = None):
    """Constructs a launch action for an Xcode scheme.

    Args:
        target: A target label as a `string` value.
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
        args = args,
        env = env,
        working_directory = working_directory,
    )

# def _copy_launch_action(
#         launch_action,
#         target = None,
#         args = None,
#         env = None,
#         working_directory = None):
#     if launch_action == None:
#         return None
#     return _launch_action(
#         target = target if target != None else launch_action.target,
#         args = args if args != None else launch_action.args,
#         env = env if env != None else launch_action.env,
#         working_directory = working_directory if working_directory != None else launch_action.working_directory,
#     )

def _replace_labels_with_target_ids(scheme, configuration):
    new_build_action = None
    build_action = scheme.build_action
    if build_action != None:
        new_build_action = _build_action(
            targets = [
                get_id(t, configuration)
                for t in build_action.targets
            ],
        )

    new_test_action = None
    test_action = scheme.test_action
    if test_action != None:
        new_test_action = _test_action(
            targets = [
                get_id(t, configuration)
                for t in test_action.targets
            ],
        )

    new_launch_action = None
    launch_action = scheme.launch_action
    if launch_action != None:
        new_launch_action = _launch_action(
            target = get_id(launch_action.target, configuration),
            args = launch_action.args,
            env = launch_action.env,
            working_directory = launch_action.working_directory,
        )

    return _scheme(
        name = scheme.name,
        build_action = new_build_action,
        test_action = new_test_action,
        launch_action = new_launch_action,
    )

xcode_schemes_internal = struct(
    scheme = _scheme,
    build_action = _build_action,
    test_action = _test_action,
    launch_action = _launch_action,
    replace_labels_with_target_ids = _replace_labels_with_target_ids,
)
