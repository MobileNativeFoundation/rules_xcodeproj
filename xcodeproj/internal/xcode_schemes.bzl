"""API for defining custom Xcode schemes"""

load("@bazel_skylib//lib:sets.bzl", "sets")
load(":bazel_labels.bzl", _bazel_labels = "bazel_labels")
load(":xcode_schemes_internal.bzl", "xcode_schemes_internal")

_DEFAULT_BUILD_CONFIGURATION_NAME = "Debug"

def _focus_schemes(schemes, focused_targets):
    """Filter/adjust a `sequence` of schemes to only include focused targets.

    Args:
        schemes: A `sequence` of `struct` values as returned by
            `xcode_schemes.scheme`.
        focused_targets: A `sequence` of `string` values representing Bazel
            labels of focused targets.

    Returns:
        A `sequence` of `struct` values as returned by `xcode_schemes.scheme`.
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
                label
                for label in build_action.targets
                if sets.contains(focused_targets, label)
            ]
            if build_targets:
                build_action = xcode_schemes_internal.build_action(
                    targets = build_targets,
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

def _unfocus_schemes(schemes, unfocused_targets):
    """Filter/adjust a `sequence` of schemes to exclude unfocused targets.

    Args:
        schemes: A `sequence` of `struct` values as returned by
            `xcode_schemes.scheme`.
        unfocused_targets: A `sequence` of `string` values representing Bazel
            labels of unfocused targets.

    Returns:
        A `sequence` of `struct` values as returned by `xcode_schemes.scheme`.
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
                label
                for label in build_action.targets
                if not sets.contains(unfocused_targets, label)
            ]
            if build_targets:
                build_action = xcode_schemes_internal.build_action(
                    targets = build_targets,
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

def make_xcode_schemes(bazel_labels):
    """Create an `xcode_schemes` module.

    Args:
        bazel_labels: A `bazel_labels` module.

    Returns:
        A `struct` that can be used as a `bazel_labels` module.
    """

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
        return xcode_schemes_internal.build_target(
            label = bazel_labels.normalize(label),
            build_for = build_for,
        )

    def _test_action(targets):
        """Constructs a test action for an Xcode scheme.

        Args:
            targets: A `sequence` of target labels as `string` values.

        Return:
            A `struct` representing a test action.
        """
        return xcode_schemes_internal.test_action(
            targets = [
                bazel_labels.normalize(t)
                for t in targets
            ],
            build_configuration_name = _DEFAULT_BUILD_CONFIGURATION_NAME,
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
                working directory in the Xcode scheme's launch action.

        Return:
            A `struct` representing a launch action.
        """
        return xcode_schemes_internal.launch_action(
            build_configuration_name = _DEFAULT_BUILD_CONFIGURATION_NAME,
            target = bazel_labels.normalize(target),
            args = args,
            env = env,
            working_directory = working_directory,
        )

    return struct(
        scheme = xcode_schemes_internal.scheme,
        build_action = xcode_schemes_internal.build_action,
        build_target = _build_target,
        build_for = xcode_schemes_internal.build_for,
        test_action = _test_action,
        launch_action = _launch_action,
        focus_schemes = _focus_schemes,
        unfocus_schemes = _unfocus_schemes,
        DEFAULT_BUILD_CONFIGURATION_NAME = _DEFAULT_BUILD_CONFIGURATION_NAME,
    )

xcode_schemes = make_xcode_schemes(
    bazel_labels = _bazel_labels,
)
