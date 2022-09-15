"""API for defining custom Xcode schemes"""

load("@bazel_skylib//lib:sets.bzl", "sets")
load(":bazel_labels.bzl", _bazel_labels = "bazel_labels")
load(":xcode_schemes_internal.bzl", "xcode_schemes_internal")

_DEFAULT_BUILD_CONFIGURATION_NAME = "Debug"

def focus_schemes(schemes, focused_targets):
    """Filter/adjust a `sequence` of schemes to only include focused targets.

    Args:
        schemes: A `sequence` of values returned by `xcode_schemes.scheme`.
        focused_targets: A `sequence` of `string` values representing Bazel
            labels of focused targets.

    Returns:
        A `sequence` of values returned by `xcode_schemes.scheme`.
        Will only include schemes that have at least one target in
        `focused_targets`. Some actions might be removed if they reference
        unfocused targets.
    """
    focused_targets = sets.make(focused_targets)

    focused_schemes = []
    for scheme in schemes:
        build_action = scheme.build_action
        if build_action:
            build_targets = [
                build_target
                for build_target in build_action.targets
                if sets.contains(focused_targets, build_target.label)
            ]
            if build_targets:
                build_action = xcode_schemes_internal.build_action(
                    targets = build_targets,
                    pre_actions = [
                        pre_action
                        for pre_action in build_action.pre_actions
                        if (not pre_action.expand_variables_based_on
                            or sets.contains(
                                focused_targets,
                                pre_action.expand_variables_based_on,
                            )
                        )
                    ],
                    post_actions = [
                        post_action
                        for post_action in build_action.post_actions
                        if (not post_action.expand_variables_based_on
                            or sets.contains(
                                focused_targets,
                                post_action.expand_variables_based_on,
                            )
                        )
                    ],
                )
            else:
                build_action = None
        else:
            build_action = None

        test_action = scheme.test_action
        if test_action:
            test_targets = [
                label
                for label in test_action.targets
                if sets.contains(focused_targets, label)
            ]
            if test_targets:
                build_configuration_name = test_action.build_configuration_name
                test_action = xcode_schemes_internal.test_action(
                    targets = test_targets,
                    build_configuration_name = build_configuration_name,
                    args = test_action.args,
                    env = test_action.env,
                )
            else:
                test_action = None
        else:
            test_action = None

        launch_action = scheme.launch_action
        if (launch_action and
            sets.contains(focused_targets, launch_action.target)):
            launch_action = scheme.launch_action
        else:
            launch_action = None

        if build_action or test_action or launch_action:
            focused_schemes.append(xcode_schemes_internal.scheme(
                name = scheme.name,
                build_action = build_action,
                test_action = test_action,
                launch_action = launch_action,
            ))

    return focused_schemes

def unfocus_schemes(schemes, unfocused_targets):
    """Filter/adjust a `sequence` of schemes to exclude unfocused targets.

    Args:
        schemes: A `sequence` of values returned by `xcode_schemes.scheme`.
        unfocused_targets: A `sequence` of `string` values representing Bazel
            labels of unfocused targets.

    Returns:
        A `sequence` of values returned by `xcode_schemes.scheme`.
        Will only include schemes that have at least one target not in
        `unfocused_targets`. Some actions might be removed if they reference
        unfocused targets.
    """
    unfocused_targets = sets.make(unfocused_targets)

    focused_schemes = []
    for scheme in schemes:
        build_action = scheme.build_action
        if build_action:
            build_targets = [
                build_target
                for build_target in build_action.targets
                if not sets.contains(unfocused_targets, build_target.label)
            ]
            if build_targets:
                build_action = xcode_schemes_internal.build_action(
                    targets = build_targets,
                    pre_actions = [
                        pre_action
                        for pre_action in build_action.pre_actions
                        if (not pre_action.expand_variables_based_on or
                            not sets.contains(
                                unfocused_targets,
                                pre_action.expand_variables_based_on,
                            )
                        )
                    ],
                    post_actions = [
                        post_action
                        for post_action in build_action.post_actions
                        if (not post_action.expand_variables_based_on or
                            not sets.contains(
                                unfocused_targets,
                                post_action.expand_variables_based_on,
                            )
                        )
                    ],
                )
            else:
                build_action = None
        else:
            build_action = None

        test_action = scheme.test_action
        if test_action:
            test_targets = [
                label
                for label in test_action.targets
                if not sets.contains(unfocused_targets, label)
            ]
            if test_targets:
                build_configuration_name = test_action.build_configuration_name
                test_action = xcode_schemes_internal.test_action(
                    targets = test_targets,
                    build_configuration_name = build_configuration_name,
                    args = test_action.args,
                    env = test_action.env,
                )
            else:
                test_action = None
        else:
            test_action = None

        launch_action = scheme.launch_action
        if (launch_action and
            not sets.contains(unfocused_targets, launch_action.target)):
            launch_action = scheme.launch_action
        else:
            launch_action = None

        focused_schemes.append(xcode_schemes_internal.scheme(
            name = scheme.name,
            build_action = build_action,
            test_action = test_action,
            launch_action = launch_action,
        ))

    return focused_schemes

def _pre_post_action(*, name = "Run Script", script, expand_variables_based_on):
    """Constructs a pre or post action for a step of the scheme.

    Args:
        name: Title of the script.
        script: The script text.
        expand_variables_based_on: Optional. The label of the target that
            environment variables will expand based on.

    Returns:
        A `struct` representing a scheme's step pre or post action.
    """
    return struct(
        script = script,
        expand_variables_based_on = expand_variables_based_on,
        name = name,
    )

def make_xcode_schemes(bazel_labels):
    """Create an `xcode_schemes` module.

    Args:
        bazel_labels: A `bazel_labels` module.

    Returns:
        A `struct` that can be used as a `xcode_schemes` module.
    """

    def _build_action(targets, *, pre_actions = [], post_actions = []):
        """Constructs a build action for an Xcode scheme.

        Args:
            targets: A `sequence` of elements that are either `struct` values as
                created by `xcode_schemes.build_target`, or a target label as a
                `string` value.
            pre_actions: A `sequence` of `struct` values as created by
                `xcode_schemes.pre_action`.
            post_actions: A `sequence` of `struct` values as created by
                `xcode_schemes.post_action`.

        Returns:
            A `struct` representing a build action.
        """

        def _pre_post_actions(actions):
            return [
                _pre_post_action(
                    script = action.script,
                    expand_variables_based_on = bazel_labels.normalize(action.expand_variables_based_on) if action.expand_variables_based_on else None,
                    name = action.name,
                )
                for action in actions
            ]

        return xcode_schemes_internal.build_action(
            targets = [
                _build_target(target) if type(target) == "string" else target
                for target in targets
            ],
            pre_actions = _pre_post_actions(pre_actions),
            post_actions = _pre_post_actions(post_actions),
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
        if not build_for:
            build_for = xcode_schemes_internal.BUILD_FOR_ALL_ENABLED
        return xcode_schemes_internal.build_target(
            label = bazel_labels.normalize(label),
            build_for = build_for,
        )

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
                 working directory in the Xcode scheme's launch action. Relative
                 paths will be relative to the value of `target`'s
                 `BUILT_PRODUCTS_DIR`, which is unique to it.

        Returns:
            A `struct` representing a launch action.
        """
        return xcode_schemes_internal.launch_action(
            build_configuration_name = _DEFAULT_BUILD_CONFIGURATION_NAME,
            target = bazel_labels.normalize(target),
            args = args,
            env = env,
            working_directory = working_directory,
        )

    def _test_action(
            targets,
            args = None,
            env = None,
            expand_variables_based_on = None):
        """Constructs a test action for an Xcode scheme.

        Args:
            targets: A `sequence` of target labels as `string` values.
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

        # Normalize the value for `expand_variables_based_on`
        if expand_variables_based_on:
            if expand_variables_based_on.lower() == "none":
                expand_variables_based_on = "none"
            else:
                expand_variables_based_on = bazel_labels.normalize(
                    expand_variables_based_on,
                )

        return xcode_schemes_internal.test_action(
            targets = [
                bazel_labels.normalize(t)
                for t in targets
            ],
            build_configuration_name = _DEFAULT_BUILD_CONFIGURATION_NAME,
            args = args,
            env = env,
            expand_variables_based_on = expand_variables_based_on,
        )

    return struct(
        scheme = xcode_schemes_internal.scheme,
        build_action = _build_action,
        build_target = _build_target,
        build_for = xcode_schemes_internal.build_for,
        build_for_values = xcode_schemes_internal.build_for_values,
        launch_action = _launch_action,
        test_action = _test_action,
        pre_post_action = _pre_post_action,
        DEFAULT_BUILD_CONFIGURATION_NAME = _DEFAULT_BUILD_CONFIGURATION_NAME,
        BUILD_FOR_ALL_ENABLED = xcode_schemes_internal.BUILD_FOR_ALL_ENABLED,
    )

xcode_schemes = make_xcode_schemes(
    bazel_labels = _bazel_labels,
)
