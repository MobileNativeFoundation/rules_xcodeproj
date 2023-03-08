"""API for defining custom Xcode schemes"""

load(":bazel_labels.bzl", _bazel_labels = "bazel_labels")
load(":xcode_schemes_internal.bzl", "xcode_schemes_internal")

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
    focused_targets = {label: None for label in focused_targets}

    focused_schemes = []
    for scheme in schemes:
        build_action = scheme.build_action
        if build_action:
            build_targets = [
                build_target
                for build_target in build_action.targets
                if build_target.label in focused_targets
            ]
            if build_targets:
                build_action = xcode_schemes_internal.build_action(
                    targets = build_targets,
                    pre_actions = [
                        pre_action
                        for pre_action in build_action.pre_actions
                        if (
                            not pre_action.expand_variables_based_on or
                            pre_action.expand_variables_based_on in focused_targets
                        )
                    ],
                    post_actions = [
                        post_action
                        for post_action in build_action.post_actions
                        if (
                            not post_action.expand_variables_based_on or
                            post_action.expand_variables_based_on in focused_targets
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
                if label in focused_targets
            ]
            if test_targets:
                build_configuration = test_action.build_configuration
                test_action = xcode_schemes_internal.test_action(
                    targets = test_targets,
                    build_configuration = build_configuration,
                    args = test_action.args,
                    diagnostics = test_action.diagnostics,
                    env = test_action.env,
                    pre_actions = [
                        pre_action
                        for pre_action in test_action.pre_actions
                        if (
                            not pre_action.expand_variables_based_on or
                            pre_action.expand_variables_based_on in focused_targets
                        )
                    ],
                    post_actions = [
                        post_action
                        for post_action in test_action.post_actions
                        if (
                            not post_action.expand_variables_based_on or
                            post_action.expand_variables_based_on in focused_targets
                        )
                    ],
                )
            else:
                test_action = None
        else:
            test_action = None

        launch_action = scheme.launch_action
        if launch_action and launch_action.target in focused_targets:
            launch_action = scheme.launch_action
        else:
            launch_action = None

        profile_action = scheme.profile_action
        if profile_action and profile_action.target in focused_targets:
            profile_action = scheme.profile_action
        else:
            profile_action = None

        if build_action or launch_action or profile_action or test_action:
            focused_schemes.append(xcode_schemes_internal.scheme(
                name = scheme.name,
                build_action = build_action,
                launch_action = launch_action,
                profile_action = profile_action,
                test_action = test_action,
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
    unfocused_targets = {label: None for label in unfocused_targets}

    focused_schemes = []
    for scheme in schemes:
        build_action = scheme.build_action
        if build_action:
            build_targets = [
                build_target
                for build_target in build_action.targets
                if build_target.label not in unfocused_targets
            ]
            if build_targets:
                build_action = xcode_schemes_internal.build_action(
                    targets = build_targets,
                    pre_actions = [
                        pre_action
                        for pre_action in build_action.pre_actions
                        if (
                            not pre_action.expand_variables_based_on or
                            pre_action.expand_variables_based_on not in unfocused_targets
                        )
                    ],
                    post_actions = [
                        post_action
                        for post_action in build_action.post_actions
                        if (
                            not post_action.expand_variables_based_on or
                            post_action.expand_variables_based_on not in unfocused_targets
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
                if label not in unfocused_targets
            ]
            if test_targets:
                build_configuration = test_action.build_configuration
                test_action = xcode_schemes_internal.test_action(
                    targets = test_targets,
                    build_configuration = build_configuration,
                    args = test_action.args,
                    diagnostics = test_action.diagnostics,
                    env = test_action.env,
                    pre_actions = [
                        pre_action
                        for pre_action in test_action.pre_actions
                        if (
                            not pre_action.expand_variables_based_on or
                            pre_action.expand_variables_based_on not in unfocused_targets
                        )
                    ],
                    post_actions = [
                        post_action
                        for post_action in test_action.post_actions
                        if (
                            not post_action.expand_variables_based_on or
                            post_action.expand_variables_based_on not in unfocused_targets
                        )
                    ],
                )
            else:
                test_action = None
        else:
            test_action = None

        launch_action = scheme.launch_action
        if launch_action and launch_action.target not in unfocused_targets:
            launch_action = scheme.launch_action
        else:
            launch_action = None

        profile_action = scheme.profile_action
        if profile_action and profile_action.target not in unfocused_targets:
            profile_action = scheme.profile_action
        else:
            profile_action = None

        focused_schemes.append(xcode_schemes_internal.scheme(
            name = scheme.name,
            build_action = build_action,
            launch_action = launch_action,
            profile_action = profile_action,
            test_action = test_action,
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

        return xcode_schemes_internal.build_action(
            targets = [
                _build_target(target) if type(target) == "string" else target
                for target in targets
            ],
            pre_actions = _pre_post_actions(pre_actions),
            post_actions = _pre_post_actions(post_actions),
        )

    def _pre_post_actions(actions):
        return [
            _pre_post_action(
                script = action.script,
                expand_variables_based_on = (
                    bazel_labels.normalize_string(
                        action.expand_variables_based_on,
                    ) if action.expand_variables_based_on else None
                ),
                name = action.name,
            )
            for action in actions
        ]

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
            label = bazel_labels.normalize_string(label),
            build_for = build_for,
        )

    def _sanitizers(
            address = False,
            thread = False,
            undefined_behavior = False):
        """Constructs the scheme's sanitizers' default state. The state can also be modified in Xcode.

        Args:
            address: Optional. A boolean value representing
                whether the address sanitizer should be enabled or not.
            thread: Optional. A boolean value representing
                whether the thread sanitizer should be enabled or not.
            undefined_behavior: Optional. A boolean value representing
                whether the undefined behavior sanitizer should be enabled or not.
        """
        if address and thread:
            fail("Address Sanitizer cannot be used together with Thread Sanitizer.")
        return struct(
            address = address,
            thread = thread,
            undefined_behavior = undefined_behavior,
        )

    def _diagnostics(sanitizers = None):
        """Constructs the scheme's diagnostics.

        Args:
            sanitizers: Optional. A `struct` value as created by
                `xcode_schemes.sanitizers`.

        Returns:
            A `struct` representing scheme's diagnostics.
        """
        return struct(
            sanitizers = sanitizers,
        )

    def _launch_action(
            target,
            args = None,
            build_configuration = None,
            diagnostics = None,
            env = None,
            working_directory = None):
        """Constructs a launch action for an Xcode scheme.

        Args:
            target: A target label as a `string` value.
            args: Optional. A `list` of `string` arguments that should be passed
                to the target when executed.
            build_configuration: Optional. The name of the Xcode configuration
                to use for this action. If not set, then the configuration
                determined by `xcodeproj.default_xcode_configuration` will be
                used.
            diagnostics: Optional. A value returned by
                `xcode_schemes.diagnostics`.
            env: Optional. A `dict` of `string` values that will be set as
                environment variables when the target is executed.
            working_directory: Optional. A `string` that will be set as the
                custom working directory in the Xcode scheme's launch action.
                Relative paths will be relative to the value of `target`'s
                `BUILT_PRODUCTS_DIR`, which is unique to it.

        Returns:
            A `struct` representing a launch action.
        """
        return xcode_schemes_internal.launch_action(
            build_configuration = build_configuration,
            target = bazel_labels.normalize_string(target),
            args = args,
            diagnostics = diagnostics,
            env = env,
            working_directory = working_directory,
        )

    def _profile_action(
            target,
            args = None,
            build_configuration = None,
            env = None,
            working_directory = None):
        """Constructs a profile action for an Xcode scheme.

        Args:
            target: A target label as a `string` value.
            args: Optional. A `list` of `string` arguments that should be passed
                to the target when executed. If both this and `env` are `None`
                (not just empty), then the launch action's arguments will be
                inherited.
            build_configuration: Optional. The name of the Xcode configuration
                to use for this action. If not set, then the configuration
                determined by `xcodeproj.default_xcode_configuration` will be
                used.
            env: Optional. A `dict` of `string` values that will be set as
                environment variables when the target is executed. If both this
                and `args` are `None` (not just empty), then the launch action's
                environment variables will be inherited.
            working_directory: Optional. A `string` that will be set as the
                custom working directory in the Xcode scheme's launch action.
                Relative paths will be relative to the value of `target`'s
                `BUILT_PRODUCTS_DIR`, which is unique to it.

        Returns:
            A `struct` representing a profile action.
        """
        return xcode_schemes_internal.profile_action(
            build_configuration = build_configuration,
            target = bazel_labels.normalize_string(target),
            args = args,
            env = env,
            working_directory = working_directory,
        )

    def _test_action(
            targets,
            args = None,
            build_configuration = None,
            diagnostics = None,
            env = None,
            expand_variables_based_on = None,
            pre_actions = [],
            post_actions = []):
        """Constructs a test action for an Xcode scheme.

        Args:
            targets: A `sequence` of target labels as `string` values.
            args: Optional. A `list` of `string` arguments that should be passed
                to the target when executed. If both this and `env` are `None`
                (not just empty), then the launch action's arguments will be
                inherited.
            build_configuration: Optional. The name of the Xcode configuration
                to use for this action. If not set, then the configuration
                determined by `xcodeproj.default_xcode_configuration` will be
                used.
            diagnostics: Optional. A value returned by
                `xcode_schemes.diagnostics`.
            env: Optional. A `dict` of `string` values that will be set as
                environment variables when the target is executed. If both this
                and `args` are `None` (not just empty), then the launch action's
                environment variables will be inherited.
            expand_variables_based_on: Optional. One of the specified test
                target labels. If no value is provided, one of the test targets
                will be selected. If no expansion context is desired, use the
                `string` value `none`.
            pre_actions: Optional. A `sequence` of `struct` values as created by
                `xcode_schemes.pre_post_action`.
            post_actions: Optional. A `sequence` of `struct` values as created by
                `xcode_schemes.pre_post_action`.

        Returns:
            A `struct` representing a test action.
        """

        # Normalize the value for `expand_variables_based_on`
        if expand_variables_based_on:
            if expand_variables_based_on.lower() == "none":
                expand_variables_based_on = "none"
            else:
                expand_variables_based_on = bazel_labels.normalize_string(
                    expand_variables_based_on,
                )

        return xcode_schemes_internal.test_action(
            targets = [
                bazel_labels.normalize_string(t)
                for t in targets
            ],
            build_configuration = build_configuration,
            args = args,
            diagnostics = diagnostics,
            env = env,
            expand_variables_based_on = expand_variables_based_on,
            pre_actions = _pre_post_actions(pre_actions),
            post_actions = _pre_post_actions(post_actions),
        )

    return struct(
        scheme = xcode_schemes_internal.scheme,
        build_action = _build_action,
        build_target = _build_target,
        build_for = xcode_schemes_internal.build_for,
        build_for_values = xcode_schemes_internal.build_for_values,
        launch_action = _launch_action,
        profile_action = _profile_action,
        test_action = _test_action,
        diagnostics = _diagnostics,
        sanitizers = _sanitizers,
        pre_post_action = _pre_post_action,
        BUILD_FOR_ALL_ENABLED = xcode_schemes_internal.BUILD_FOR_ALL_ENABLED,
    )

xcode_schemes = make_xcode_schemes(
    bazel_labels = _bazel_labels,
)
