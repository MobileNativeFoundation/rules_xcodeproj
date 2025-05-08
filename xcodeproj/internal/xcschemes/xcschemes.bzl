"""Module for defining custom Xcode schemes (`.xcscheme`s)."""

load("//xcodeproj/internal:memory_efficiency.bzl", "FALSE_ARG", "TRUE_ARG")

# Scheme

def _scheme(name, *, profile = "same_as_run", run = None, test = None):
    """Defines a custom scheme.

    Args:
        name: Positional. The name of the scheme.
        profile: A value returned by [`xcschemes.profile`](#xcschemes.profile),
            or the string `"same_as_run"`.

            If `"same_as_run"`, the same targets will be built for the Profile
            action as are built for the Run action (defined by
            [`xcschemes.run`](#xcschemes.run)). If `None`, `xcschemes.profile()`
            will be used, which means no targets will be built for the Profile
            action.
        run: A value returned by [`xcschemes.run`](#xcschemes.run).

            If `None`, `xcschemes.run()` will be used, which means no targets
            will be built for the Run action, except for `build_targets` and
            `library_targets` specified in
            [`xcschemes.profile`](#xcschemes.profile) and
            [`xcschemes.test`](#xcschemes.test).
        test: A value returned by [`xcschemes.test`](#xcschemes.test).

            If `None`, `xcschemes.test()` will be used, which means no targets
            will be built for the Test action.
    """
    if not name:
        fail("""
`name` must be provided to `xcschemes.scheme`.
""")

    return struct(
        name = name,
        profile = profile,
        run = run,
        test = test,
    )

# Actions

def _profile(
        *,
        args = "inherit",
        build_targets = [],
        env = "inherit",
        env_include_defaults = True,
        launch_target = None,
        use_run_args_and_env = None,
        xcode_configuration = None):
    """Defines the Profile action.

    Args:
        args: Command-line arguments to use when profiling the launch target.

            If `"inherit"`, then the arguments will be supplied by the launch
            target (e.g.
            [`cc_binary.args`](https://bazel.build/reference/be/common-definitions#binary.args)).
            Otherwise, the `list` of arguments will be set as provided, and
            `None` or `[]` will result in no command-line arguments.

            Each element of the `list` can either be a string or a value
            returned by [`xcschemes.arg`](#xcschemes.arg). If an element is a
            string, it will be transformed into `xcschemes.arg(element)`. For
            example,
            ```
            xcschemes.profile(
                args = [
                    "-arg1",
                    xcschemes.arg("-arg2", enabled = False),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.profile(
                args = [
                    xcschemes.arg("-arg1"),
                    xcschemes.arg("-arg2", enabled = False),
                ],
            )
            ```
        build_targets: Additional targets to build when profiling.

            Each element of the `list` can be a label string, a value returned
            by
            [`xcschemes.top_level_build_target`](#xcschemes.top_level_build_target),
            or a value returned by
            [`xcschemes.top_level_anchor_target`](#xcschemes.top_level_anchor_target).
            If an element is a label string, it will be transformed into
            `xcschemes.top_level_build_target(label_str)`. For example,
            ```
            xcschemes.profile(
                build_targets = [
                    xcschemes.top_level_anchor_target(
                        "//App",
                        &hellip;
                    ),
                    "//App:Test",
                    xcschemes.top_level_build_target(
                        "//CommandLineTool",
                        &hellip;
                    ),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.profile(
                build_targets = [
                    xcschemes.top_level_anchor_target(
                        "//App",
                        &hellip;
                    ),
                    xcschemes.top_level_build_target("//App:Test"),
                    xcschemes.top_level_build_target(
                        "//CommandLineTool",
                        &hellip;
                    ),
                ],
            )
            ```
        env: Environment variables to use when profiling the launch target.

            If set to `"inherit"`, then the environment variables will be
            supplied by the launch target (e.g.
            [`cc_binary.env`](https://bazel.build/reference/be/common-definitions#binary.env)).
            Otherwise, the `dict` of environment variables will be set as
            provided, and `None` or `{}` will result in no environment
            variables.

            Each value of the `dict` can either be a string or a value returned
            by [`xcschemes.env_value`](#xcschemes.env_value). If a value is a
            string, it will be transformed into `xcschemes.env_value(value)`.
            For example,
            ```
            xcschemes.profile(
                env = {
                    "VAR1": "value 1",
                    "VAR 2": xcschemes.env_value("value2", enabled = False),
                },
            )
            ```
            will be transformed into:
            ```
            xcschemes.profile(
                env = {
                    "VAR1": xcschemes.env_value("value 1"),
                    "VAR 2": xcschemes.env_value("value2", enabled = False),
                },
            )
            ```
        env_include_defaults: Whether to include the rules_xcodeproj provided
            default Bazel environment variables (e.g.
            `BUILD_WORKING_DIRECTORY` and `BUILD_WORKSPACE_DIRECTORY`), in
            addition to any set by [`env`](#xcschemes.profile-env). This does
            not apply to [`xcschemes.launch_path`](#xcschemes.launch_path)s.
        launch_target: The target to launch when profiling.

            Can be `None`, a label string, a value returned by
            [`xcschemes.launch_target`](#xcschemes.launch_target),
            or a value returned by [`xcschemes.launch_path`](#xcschemes.launch_path).
            If a label string, `xcschemes.launch_target(label_str)` will be used. If
            `None`, `xcschemes.launch_target()` will be used, which means no
            launch target will be set (i.e. the `Executable` dropdown will be
            set to `None`).
        use_run_args_and_env: Whether the `Use the Run action's arguments
            and environment variables` checkbox is checked.

            If `True`, command-line arguments and environment variables will
            still be set as defined by [`args`](#xcschemes.profile-args) and
            [`env`](#xcschemes.profile-env), but will be ignored by Xcode unless
            you manually uncheck this checkbox in the scheme. If `None`, `True`
            will be used if [`args`](#xcschemes.profile-args) and
            [`env`](#xcschemes.profile-env) are both `"inherit"`, otherwise
            `False` will be used.

            A value of `True` will be ignored (i.e. treated as `False`) if
            [`run.launch_target`](#xcschemes.run-launch_target) is not set to a
            target.
        xcode_configuration: The name of the Xcode configuration to use to build
            the targets referenced in the Profile action (i.e in the
            [`build_targets`](#xcschemes.profile-build_targets) and
            [`launch_target`](#xcschemes.profile-launch_target) attributes).

            If not set, the value of
            [`xcodeproj.default_xcode_configuration`](#xcodeproj-default_xcode_configuration)
            is used.
    """
    if use_run_args_and_env == None:
        use_run_args_and_env = args == "inherit" and env == "inherit"

    return struct(
        args = args or [],
        build_targets = build_targets or [],
        env = env or {},
        env_include_defaults = TRUE_ARG if env_include_defaults else FALSE_ARG,
        launch_target = launch_target,
        use_run_args_and_env = TRUE_ARG if use_run_args_and_env else FALSE_ARG,
        xcode_configuration = xcode_configuration or "",
    )

def _run(
        *,
        args = "inherit",
        build_targets = [],
        diagnostics = None,
        env = "inherit",
        env_include_defaults = True,
        launch_target = None,
        xcode_configuration = None):
    """Defines the Run action.

    Args:
        args: Command-line arguments to use when running the launch target.

            If `"inherit"`, then the arguments will be supplied by the launch
            target (e.g.
            [`cc_binary.args`](https://bazel.build/reference/be/common-definitions#binary.args)).
            Otherwise, the `list` of arguments will be set as provided, and
            `None` or `[]` will result in no command-line arguments.

            Each element of the `list` can either be a string or a value
            returned by [`xcschemes.arg`](#xcschemes.arg). If an element is a
            string, it will be transformed into `xcschemes.arg(element)`. For
            example,
            ```
            xcschemes.run(
                args = [
                    "-arg1",
                    xcschemes.arg("-arg2", enabled = False),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.run(
                args = [
                    xcschemes.arg("-arg1"),
                    xcschemes.arg("-arg2", enabled = False),
                ],
            )
            ```
        build_targets: Additional targets to build when running.

            Each element of the `list` can be a label string, a value returned
            by
            [`xcschemes.top_level_build_target`](#xcschemes.top_level_build_target),
            or a value returned by
            [`xcschemes.top_level_anchor_target`](#xcschemes.top_level_anchor_target).
            If an element is a label string, it will be transformed into
            `xcschemes.top_level_build_target(label_str)`. For example,
            ```
            xcschemes.run(
                build_targets = [
                    xcschemes.top_level_anchor_target(
                        "//App",
                        &hellip;
                    ),
                    "//App:Test",
                    xcschemes.top_level_build_target(
                        "//CommandLineTool",
                        &hellip;
                    ),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.run(
                build_targets = [
                    xcschemes.top_level_anchor_target(
                        "//App",
                        &hellip;
                    ),
                    xcschemes.top_level_build_target("//App:Test"),
                    xcschemes.top_level_build_target(
                        "//CommandLineTool",
                        &hellip;
                    ),
                ],
            )
            ```
        diagnostics: The diagnostics to enable when running the launch target.

            Can be `None` or a value returned by
            [`xcschemes.diagnostics`](#xcschemes.diagnostics). If `None`,
            `xcschemes.diagnostics()` will be used, which means no diagnostics
            will be enabled.
        env: Environment variables to use when running the launch target.

            If set to `"inherit"`, then the environment variables will be
            supplied by the launch target (e.g.
            [`cc_binary.env`](https://bazel.build/reference/be/common-definitions#binary.env)).
            Otherwise, the `dict` of environment variables will be set as
            provided, and `None` or `{}` will result in no environment
            variables.

            Each value of the `dict` can either be a string or a value returned
            by [`xcschemes.env_value`](#xcschemes.env_value). If a value is a
            string, it will be transformed into `xcschemes.env_value(value)`.
            For example,
            ```
            xcschemes.run(
                env = {
                    "VAR1": "value 1",
                    "VAR 2": xcschemes.env_value("value2", enabled = False),
                },
            )
            ```
            will be transformed into:
            ```
            xcschemes.run(
                env = {
                    "VAR1": xcschemes.env_value("value 1"),
                    "VAR 2": xcschemes.env_value("value2", enabled = False),
                },
            )
            ```
        env_include_defaults: Whether to include the rules_xcodeproj provided
            default Bazel environment variables (e.g.
            `BUILD_WORKING_DIRECTORY` and `BUILD_WORKSPACE_DIRECTORY`), in
            addition to any set by [`env`](#xcschemes.run-env). This does
            not apply to [`xcschemes.launch_path`](#xcschemes.launch_path)s.
        launch_target: The target to launch when running.

            Can be `None`, a label string, a value returned by
            [`xcschemes.launch_target`](#xcschemes.launch_target),
            or a value returned by [`xcschemes.launch_path`](#xcschemes.launch_path).
            If a label string, `xcschemes.launch_target(label_str)` will be used. If
            `None`, `xcschemes.launch_target()` will be used, which means no
            launch target will be set (i.e. the `Executable` dropdown will be
            set to `None`).
        xcode_configuration: The name of the Xcode configuration to use to build
            the targets referenced in the Run action (i.e in the
            [`build_targets`](#xcschemes.run-build_targets) and
            [`launch_target`](#xcschemes.run-launch_target) attributes).

            If not set, the value of
            [`xcodeproj.default_xcode_configuration`](#xcodeproj-default_xcode_configuration)
            is used.
    """
    return struct(
        args = args or [],
        build_targets = build_targets or [],
        diagnostics = diagnostics,
        env = env or {},
        env_include_defaults = TRUE_ARG if env_include_defaults else FALSE_ARG,
        launch_target = launch_target,
        xcode_configuration = xcode_configuration or "",
    )

def _test(
        *,
        args = "inherit",
        build_targets = [],
        diagnostics = None,
        env = "inherit",
        env_include_defaults = True,
        test_options = None,
        test_targets = [],
        use_run_args_and_env = None,
        xcode_configuration = None):
    """Defines the Test action.

    Args:
        args: Command-line arguments to use when testing.

            If `"inherit"`, then the arguments will be supplied by the test
            targets (e.g.
            [`cc_test.args`](https://bazel.build/reference/be/common-definitions#binary.args)),
            as long as every test target has the same arguments. Otherwise, the
            `list` of arguments will be set as provided, and `None` or `[]` will
            result in no command-line arguments.

            Each element of the `list` can either be a string or a value
            returned by [`xcschemes.arg`](#xcschemes.arg). If an element is a
            string, it will be transformed into `xcschemes.arg(element)`. For
            example,
            ```
            xcschemes.test(
                args = [
                    "-arg1",
                    xcschemes.arg("-arg2", enabled = False),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.test(
                args = [
                    xcschemes.arg("-arg1"),
                    xcschemes.arg("-arg2", enabled = False),
                ],
            )
            ```
        build_targets: Additional targets to build when testing.

            Each element of the `list` can be a label string, a value returned
            by
            [`xcschemes.top_level_build_target`](#xcschemes.top_level_build_target),
            or a value returned by
            [`xcschemes.top_level_anchor_target`](#xcschemes.top_level_anchor_target).
            If an element is a label string, it will be transformed into
            `xcschemes.top_level_build_target(label_str)`. For example,
            ```
            xcschemes.test(
                build_targets = [
                    xcschemes.top_level_anchor_target(
                        "//App",
                        &hellip;
                    ),
                    "//App:Test",
                    xcschemes.top_level_build_target(
                        "//CommandLineTool",
                        &hellip;
                    ),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.test(
                build_targets = [
                    xcschemes.top_level_anchor_target(
                        "//App",
                        &hellip;
                    ),
                    xcschemes.top_level_build_target("//App:Test"),
                    xcschemes.top_level_build_target(
                        "//CommandLineTool",
                        &hellip;
                    ),
                ],
            )
            ```
        diagnostics: The diagnostics to enable when testing.

            Can be `None` or a value returned by
            [`xcschemes.diagnostics`](#xcschemes.diagnostics). If `None`,
            `xcschemes.diagnostics()` will be used, which means no diagnostics
            will be enabled.
        env: Environment variables to use when testing.

            If set to `"inherit"`, then the environment variables will be
            supplied by the test targets (e.g.
            [`ios_unit_test.env`](https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-ios.md#ios_unit_test-env)),
            as long as every test target has the same environment variables.
            Otherwise, the `dict` of environment variables will be set as
            provided, and `None` or `{}` will result in no environment
            variables.

            Each value of the `dict` can either be a string or a value returned
            by [`xcschemes.env_value`](#xcschemes.env_value). If a value is a
            string, it will be transformed into `xcschemes.env_value(value)`.
            For example,
            ```
            xcschemes.test(
                env = {
                    "VAR1": "value 1",
                    "VAR 2": xcschemes.env_value("value2", enabled = False),
                },
            )
            ```
            will be transformed into:
            ```
            xcschemes.test(
                env = {
                    "VAR1": xcschemes.env_value("value 1"),
                    "VAR 2": xcschemes.env_value("value2", enabled = False),
                },
            )
            ```
        env_include_defaults: Whether to include the rules_xcodeproj provided
            default Bazel environment variables (e.g.
            `BUILD_WORKING_DIRECTORY` and `BUILD_WORKSPACE_DIRECTORY`), in
            addition to any set by [`env`](#xcschemes.test-env).
        test_options: The test options to set for testing.
            Can be `None` or a value returned by
            [`xcschemes.test_options`](#xcschemes.test_options). If `None`,
            `xcschemes.test_options()` will be used, which means no additional
            test options be set.
        test_targets: The test targets to build, and possibly run, when testing.

            Each element of the `list` can be a label string or a value returned
            by [`xcschemes.test_target`](#xcschemes.test_target). If an element
            is a label string, it will be transformed into
            `xcschemes.test_target(label_str)`. For example,
            ```
            xcschemes.test(
                test_targets = [
                    "//App:Test1",
                    xcschemes.test_target(
                        "//App:Test2",
                        &hellip;
                    ),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.test(
                test_targets = [
                    xcschemes.test_target("//App:Test1"),
                    xcschemes.test_target(
                        "//App:Test2",
                        &hellip;
                    ),
                ],
            )
            ```
        use_run_args_and_env: Whether the `Use the Run action's arguments
            and environment variables` checkbox is checked.

            If `True`, command-line arguments and environment variables will
            still be set as defined by [`args`](#xcschemes.test-args) and
            [`env`](#xcschemes.test-env), but will be ignored by Xcode unless
            you manually uncheck this checkbox in the scheme. If `None`, `True`
            will be used if [`args`](#xcschemes.test-args) and
            [`env`](#xcschemes.test-env) are both `"inherit"`, otherwise
            `False` will be used.

            A value of `True` will be ignored (i.e. treated as `False`) if
            [`run.launch_target`](#xcschemes.run-launch_target) is not set to a
            target.
        xcode_configuration: The name of the Xcode configuration to use to build
            the targets referenced in the Test action (i.e in the
            [`build_targets`](#xcschemes.test-build_targets) and
            [`test_targets`](#xcschemes.test-test_targets) attributes).

            If not set, the value of
            [`xcodeproj.default_xcode_configuration`](#xcodeproj-default_xcode_configuration)
            is used.
    """
    if use_run_args_and_env == None:
        use_run_args_and_env = args == "inherit" and env == "inherit"

    return struct(
        args = args or [],
        build_targets = build_targets or [],
        diagnostics = diagnostics,
        env = env or {},
        env_include_defaults = TRUE_ARG if env_include_defaults else FALSE_ARG,
        test_options = test_options,
        test_targets = test_targets or [],
        use_run_args_and_env = TRUE_ARG if use_run_args_and_env else FALSE_ARG,
        xcode_configuration = xcode_configuration or "",
    )

# Targets

def _launch_path(
        path,
        *,
        post_actions = [],
        pre_actions = [],
        working_directory = None):
    """Defines the launch path for a pre-built executable.

    Args:
        path: Positional. The launch path for a launch target.

            The path must be an absolute path to an executable file.
            It will be set as the runnable within a launch action.
        working_directory: The working directory to use when running the launch
            target.

            If not set, the Xcode default working directory will be used (i.e.
            some directory in `DerivedData`).
        post_actions: Post-actions to run when running the launch path.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
        pre_actions: Pre-actions to run when running the launch path.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
    """

    if not path:
        fail("""
`path` must be provided to `xcschemes.launch_path`.
""")

    return struct(
        is_path = TRUE_ARG,
        path = path,
        post_actions = post_actions,
        pre_actions = pre_actions,
        working_directory = working_directory or "",
    )

def _launch_target(
        label,
        *,
        extension_host = None,
        library_targets = [],
        post_actions = [],
        pre_actions = [],
        target_environment = None,
        working_directory = None):
    """Defines a launch target.

    Args:
        label: Positional. The label string of the target to launch when
            running.
        extension_host: The label string of an extension host for the launch
            target.

            If [`label`](#xcschemes.launch_target-label) is an app extension,
            this must be set to the label string of a target that bundles the
            app extension. Otherwise, this must be `None`.
        library_targets: Additional library targets to build when running.

            Library targets must be transitive dependencies of the launch
            target.

            Each element of the `list` can be a label string or a value returned
            by [`xcschemes.library_target`](#xcschemes.library_target). If an
            element is a label string, it will be transformed into
            `xcschemes.library_target(label_str)`. For example,
            ```
            xcschemes.launch_target(
                &hellip;
                library_targets = [
                    "//Modules/Lib1",
                    xcschemes.library_target(
                        "//Modules/Lib2",
                        &hellip;
                    ),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.launch_target(
                &hellip;
                library_targets = [
                    xcschemes.library_target("//Modules/Lib1"),
                    xcschemes.library_target(
                        "//Modules/Lib2",
                        &hellip;
                    ),
                ],
            )
            ```
        post_actions: Post-actions to run when building or running the launch
            target.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
        pre_actions: Pre-actions to run when building or running the launch
            target.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
        target_environment: The
            [target environment](#top_level_target-target_environments) to use
            when determining which version of the launch target
            [`label`](#xcschemes.launch_target-label) refers to.

            If not set, the default target environment will be used (i.e.
            `"simulator"` if it's one of the available target environments,
            otherwise `"device"`).
        working_directory: The working directory to use when running the launch
            target.

            If not set, the Xcode default working directory will be used (i.e.
            some directory in `DerivedData`).
    """
    if not label:
        fail("""
`label` must be provided to `xcschemes.launch_target`.
""")

    return struct(
        extension_host = extension_host or "",
        is_path = FALSE_ARG,
        label = label,
        library_targets = library_targets,
        post_actions = post_actions,
        pre_actions = pre_actions,
        target_environment = target_environment,
        working_directory = working_directory or "",
    )

def _library_target(label, *, post_actions = [], pre_actions = []):
    """Defines a library target to build.

    A library target is any target not classified as a top-level target.
    Normally these targets are created with rules similar to `swift_library`
    or `objc_library`.

    Args:
        label: Positional. The label string of the library target.

            This must be a library target (i.e. not a top-level target); use
            the `build_targets` attribute of
            [`profile`](#xcschemes.profile-build_targets),
            [`run`](#xcschemes.run-build_targets), or
            [`test`](#xcschemes.test-build_targets) to add top-level build
            targets.
        post_actions: Post-actions to run when building or running the action
            this build target is a part of.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
        pre_actions: Pre-actions to run when building or running the action
            this build target is a part of.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
    """
    if not label:
        fail("""
`label` must be provided to `xcschemes.library_target`.
""")

    return struct(
        label = label,
        post_actions = post_actions,
        pre_actions = pre_actions,
    )

def _test_target(
        label,
        *,
        enabled = True,
        library_targets = [],
        post_actions = [],
        pre_actions = [],
        target_environment = None):
    """Defines a test target.

    Args:
        label: Positional. The label string of the test target.
        enabled: Whether the test target is enabled.

            If `True`, the checkbox for the test target will be
            checked in the scheme. An unchecked checkbox means Xcode won't
            run this test target when testing.
        library_targets: Additional library targets to build when testing.

            Library targets must be transitive dependencies of the test target.
            They must not be top-level targets; use
            [`build_targets`](#xcschemes.test-build_targets) for those.

            Each element of the `list` can be a label string or a value returned
            by [`xcschemes.library_target`](#xcschemes.library_target). If an
            element is a label string, it will be transformed into
            `xcschemes.library_target(label_str)`. For example,
            ```
            xcschemes.test_target(
                &hellip;
                library_targets = [
                    "//Modules/Lib1",
                    xcschemes.library_target(
                        "//Modules/Lib2",
                        &hellip;
                    ),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.test_target(
                &hellip;
                library_targets = [
                    xcschemes.library_target("//Modules/Lib1"),
                    xcschemes.library_target(
                        "//Modules/Lib2",
                        &hellip;
                    ),
                ],
            )
            ```
        post_actions: Post-actions to run when building or running the test
            target.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
        pre_actions: Pre-actions to run when building or running the test
            target.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
        target_environment: The
            [target environment](#top_level_target-target_environments) to use
            when determining which version of the test target
            [`label`](#xcschemes.launch_target-label) refers to.

            If not set, the default target environment will be used (i.e.
            `"simulator"` if it's one of the available target environments,
            otherwise `"device"`).
    """
    if not label:
        fail("""
`label` must be provided to `xcschemes.test_target`.
""")

    return struct(
        enabled = TRUE_ARG if enabled else FALSE_ARG,
        label = label,
        library_targets = library_targets,
        post_actions = post_actions,
        pre_actions = pre_actions,
        target_environment = target_environment,
    )

def _top_level_anchor_target(
        label,
        *,
        extension_host = None,
        library_targets,
        target_environment = None):
    """Defines a top-level anchor target for library build targets.

    Use this function to define library targets to build, when you don't want
    to also build the top-level target that depends on them. If you also want to
    build the top-level target, use
    [`top_level_build_target`](#xcschemes.top_level_build_target-library_targets)
    instead.

    Args:
        label: Positional. The label string of the top-level target.

            This must be a top-level target (i.e. not a library target); use
            the `library_targets` attribute of
            [`launch_target`](#xcschemes.launch_target-library_targets),
            [`test_target`](#xcschemes.test_target-library_targets),
            [`top_level_anchor_target`](#xcschemes.top_level_anchor_target-library_targets),
            or
            [`top_level_build_target`](#xcschemes.top_level_build_target-library_targets)
            to add library build targets.
        extension_host: The label string of an extension host for the top-level
            target.

            If [`label`](#xcschemes.top_level_build_target-label) is an app
            extension, this must be set to the label string of a target that
            bundles the app extension. Otherwise, this must be `None`.
        library_targets: The library targets to build.

            Library targets must be transitive dependencies of the top-level
            anchor target. They must not be top-level targets; instead, set
            additional values in the `build_targets` attribute that this
            `top_level_build_target` is defined in.

            Each element of the `list` can be a label string or a value returned
            by [`xcschemes.library_target`](#xcschemes.library_target). If an
            element is a label string, it will be transformed into
            `xcschemes.library_target(label_str)`. For example,
            ```
            xcschemes.top_level_anchor_target(
                &hellip;
                library_targets = [
                    "//Modules/Lib1",
                    xcschemes.library_target(
                        "//Modules/Lib2",
                        &hellip;
                    ),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.top_level_anchor_target(
                &hellip;
                library_targets = [
                    xcschemes.library_target("//Modules/Lib1"),
                    xcschemes.library_target(
                        "//Modules/Lib2",
                        &hellip;
                    ),
                ],
            )
            ```
        target_environment: The
            [target environment](#top_level_target-target_environments) to use
            when determining which version of the top-level target
            [`label`](#xcschemes.top_level_build_target-label) refers to.

            If not set, the default target environment will be used (i.e.
            `"simulator"` if it's one of the available target environments,
            otherwise `"device"`).
    """
    if not label:
        fail("""\
`label` must be provided to `xcscheme.top_level_anchor_target`.
""")
    if not library_targets:
        fail("""
`library_targets` must be non-empty for `xcscheme.top_level_anchor_target`.
""")

    return struct(
        extension_host = extension_host or "",
        include = False,
        label = label,
        library_targets = library_targets,
        post_actions = [],
        pre_actions = [],
        target_environment = target_environment,
    )

def _top_level_build_target(
        label,
        *,
        extension_host = None,
        library_targets = [],
        post_actions = [],
        pre_actions = [],
        target_environment = None):
    """Defines a top-level target to build.

    Use this function to define a top-level target, and optionally transitive
    library targets, to build. If you don't want to build the top-level target,
    and only want to build the transitive library targets, use
    [`top_level_anchor_target`](#xcschemes.top_level_anchor_target-library_targets)
    instead.

    Args:
        label: Positional. The label string of the top-level target.

            This must be a top-level target (i.e. not a library target); use
            the `library_targets` attribute of
            [`launch_target`](#xcschemes.launch_target-library_targets),
            [`test_target`](#xcschemes.test_target-library_targets),
            [`top_level_build_target`](#xcschemes.top_level_build_target-library_targets),
            or
            [`top_level_anchor_target`](#xcschemes.top_level_anchor_target-library_targets)
            to add library build targets.
        extension_host: The label string of an extension host for the top-level
            target.

            If [`label`](#xcschemes.top_level_build_target-label) is an app
            extension, this must be set to the label string of a target that
            bundles the app extension. Otherwise, this must be `None`.
        library_targets: Additional library targets to build.

            Library targets must be transitive dependencies of the top-level
            build target. They must not be top-level targets; instead, set
            additional values in the `build_targets` attribute that this
            `top_level_build_target` is defined in.

            Each element of the `list` can be a label string or a value returned
            by [`xcschemes.library_target`](#xcschemes.library_target). If an
            element is a label string, it will be transformed into
            `xcschemes.library_target(label_str)`. For example,
            ```
            xcschemes.top_level_build_target(
                &hellip;
                library_targets = [
                    "//Modules/Lib1",
                    xcschemes.library_target(
                        "//Modules/Lib2",
                        &hellip;
                    ),
                ],
            )
            ```
            will be transformed into:
            ```
            xcschemes.top_level_build_target(
                &hellip;
                library_targets = [
                    xcschemes.library_target("//Modules/Lib1"),
                    xcschemes.library_target(
                        "//Modules/Lib2",
                        &hellip;
                    ),
                ],
            )
            ```
        post_actions: Post-actions to run when building or running the action
            this build target is a part of.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
        pre_actions: Pre-actions to run when building or running the action
            this build target is a part of.

            Elements of the `list` must be values returned by functions in
            [`xcschemes.pre_post_actions`](#xcschemes.pre_post_actions).
        target_environment: The
            [target environment](#top_level_target-target_environments) to use
            when determining which version of the top-level target
            [`label`](#xcschemes.top_level_build_target-label) refers to.

            If not set, the default target environment will be used (i.e.
            `"simulator"` if it's one of the available target environments,
            otherwise `"device"`).
    """
    if not label:
        fail("""
`label` must be provided to `xcschemes.top_level_build_target`.
""")

    return struct(
        extension_host = extension_host or "",
        include = True,
        label = label,
        library_targets = library_targets,
        post_actions = post_actions,
        pre_actions = pre_actions,
        target_environment = target_environment,
    )

# `pre_post_actions`

def _build_script(title = "Run Script", *, order = None, script_text):
    """Defines a pre-action or post-action script to run when building.

    This action will appear in the Pre-actions or Post-actions section of the
    Build section of the scheme.

    Args:
        title: The title of the action.
        order: The relative order of the action within the section it appears
            in.

            If `None`, the action will be added to the end of the section, in
            an unspecified but deterministic order. Otherwise, the order should
            be an integer. Smaller order values will run before larger order
            values. rules_xcodeproj created actions (e.g. "Update .lldbinit and
            copy dSYMs") use order values 0, -100, -200, etc.
        script_text: The script text.

            The script will be run in Bazel's execution root, so you probably
            want to change to the `$SRCROOT` directory in the script.
    """
    if not title:
        fail("""
`title` must be provided to `xcschemes.pre_post_actions.build_script`.
""")
    if not script_text:
        fail("""
`script_text` must be provided to `xcschemes.pre_post_actions.build_script`.
""")

    return struct(
        for_build = True,
        order = order,
        script_text = script_text,
        title = title,
    )

def _launch_script(title = "Run Script", *, order = None, script_text):
    """Defines a pre-action or post-action script to run when running.

    This action will appear in the Pre-actions or Post-actions section of the
    Test, Run, or Profile section of the scheme.

    Args:
        title: The title of the action.
        order: The relative order of the action within the section it appears
            in.

            If `None`, the action will be added to the end of the section, in
            an unspecified but deterministic order. Otherwise, the order should
            be an integer. Smaller order values will run before larger order
            values. rules_xcodeproj created actions (e.g. "Update .lldbinit and
            copy dSYMs") use order values 0, -100, -200, etc.
        script_text: The script text.

            The script will be run in Bazel's execution root, so you probably
            want to change to the `$SRCROOT` directory in the script.
    """
    if not title:
        fail("""
`title` must be provided to `xcschemes.pre_post_actions.launch_script`.
""")
    if not script_text:
        fail("""
`script_text` must be provided to `xcschemes.pre_post_actions.launch_script`.
""")

    return struct(
        for_build = False,
        order = order,
        script_text = script_text,
        title = title,
    )

_pre_post_actions = struct(
    build_script = _build_script,
    launch_script = _launch_script,
)

# Other

def _arg(value, *, enabled = True, literal_string = True):
    """Defines a command-line argument.

    Args:
        value: Positional. The command-line argument.

            Arguments with quotes, spaces, or newlines will be escaped. You
            should not use additional quotes around arguments with spaces. If
            you include quotes around your argument, those quotes will be part
            of the argument.
        enabled: Whether the command-line argument is enabled.

            If `True`, the checkbox for the argument will be
            checked in the scheme. An unchecked checkbox means Xcode won't
            include that argument when running a target.
        literal_string: Whether `value` should be interpreted as a literal
            string.

            If `True`, any spaces will be escaped. This means that `value` will
            be passed to the launch target as a single string. If `False`, any
            spaces will not be escaped. This is useful to group multiple
            arguments under a single checkbox in Xcode.
    """
    if not value:
        fail("""
`value` must be provided to `xcschemes.arg`.
""")

    return struct(
        enabled = TRUE_ARG if enabled else FALSE_ARG,
        literal_string = TRUE_ARG if literal_string else FALSE_ARG,
        value = value,
    )

def _env_value(value, *, enabled = True):
    """Defines an environment variable value.

    Args:
        value: Positional. The environment variable value.

            Values with quotes, spaces, or newlines will be escaped. You
            should not use additional quotes around values with spaces. If
            you include quotes around your value, those quotes will be part
            of the value.
        enabled: Whether the environment variable is enabled.

            If `True`, the checkbox for the environment variable will be
            checked in the scheme. An unchecked checkbox means Xcode won't
            include that environment variable when running a target.
    """
    if not value:
        fail("""
`value` must be provided to `xcschemes.env_value`.
""")

    return struct(
        enabled = TRUE_ARG if enabled else FALSE_ARG,
        value = value,
    )

def _diagnostics(
        *,
        address_sanitizer = False,
        thread_sanitizer = False,
        undefined_behavior_sanitizer = False,
        main_thread_checker = True,
        thread_performance_checker = True):
    """Defines the diagnostics to enable.

    Args:
        address_sanitizer: Whether to enable Address Sanitizer.

            If `True`,
            [`thread_sanitizer`](#xcschemes.diagnostics-thread_sanitizer) must
            be `False`.
        thread_sanitizer: Whether to enable Thread Sanitizer.

            If `True`,
            [`address_sanitizer`](#xcschemes.diagnostics-address_sanitizer) must
            be `False`.
        undefined_behavior_sanitizer: Whether to enable Undefined Behavior
            Sanitizer.
        main_thread_checker: Whether to enable Main Thread Checker.
        thread_performance_checker: Whether to enable Thread Performance Checker.
    """
    if address_sanitizer and thread_sanitizer:
        fail("""
Address Sanitizer cannot be used together with Thread Sanitizer.
""")

    return struct(
        # Sanitizers
        address_sanitizer = TRUE_ARG if address_sanitizer else FALSE_ARG,
        thread_sanitizer = TRUE_ARG if thread_sanitizer else FALSE_ARG,
        undefined_behavior_sanitizer = (
            TRUE_ARG if undefined_behavior_sanitizer else FALSE_ARG
        ),
        # Checks
        main_thread_checker = TRUE_ARG if main_thread_checker else FALSE_ARG,
        thread_performance_checker = (
            TRUE_ARG if thread_performance_checker else FALSE_ARG
        ),
    )

def _test_options(
        *,
        app_language = None,
        app_region = None,
        code_coverage = False):
    """Defines the test options for a custom scheme.

    Args:
        app_region: Region to set in scheme.

            Defaults to system settings if not set.
        app_language: Language to set in scheme.

            Defaults to system settings if not set.
        code_coverage: Whether to enable code coverage.

            If `True`, code coverage will be enabled.
    """

    return struct(
        app_region = app_region,
        app_language = app_language,
        code_coverage = (
            TRUE_ARG if code_coverage else FALSE_ARG
        ),
    )

def _autogeneration_test(*, options = None):
    """Creates a value for the `test` argument of `xcschemes.autogeneration_config`.

    Args:
        options: Test options for autogeneration.

            Defaults to `None`.

    Returns:
        An opaque value for the
        [`test`](user-content-xcschemes.autogeneration_config-test)
        argument of `xcschemes.autogeneration_config`.
    """

    return struct(
        test_options = options,
    )

def _autogeneration_config(*, scheme_name_exclude_patterns = None, test = None):
    """Creates a value for the [`scheme_autogeneration_config`](xcodeproj-scheme_autogeneration_config) attribute of `xcodeproj`.

    Args:
        scheme_name_exclude_patterns: A `list` of regex patterns used to skip
            creating matching autogenerated schemes.

            Example:

            ```starlark
            xcodeproj(
                ...
                scheme_name_exclude_patterns = xcschemes.autogeneration_config(
                    scheme_name_exclude_patterns = [
                        ".*somePattern.*",
                        "^AnotherPattern.*",
                    ],
                ),
            )
            ```

        test: Options to use for the test action.

            Example:

            ```starlark
            xcodeproj(
                ...
                scheme_autogeneration_config = xcschemes.autogeneration_config(
                    test = xcschemes.autogeneration.test(
                        options = xcschemes.test_options(
                            app_language = "en",
                            app_region = "US",
                            code_coverage = False,
                        )
                    )
                )
            )
            ```

    Returns:
        An opaque value for the [`scheme_autogeneration_config`](xcodeproj-scheme_autogeneration_config) attribute of `xcodeproj`.
    """
    d = {}
    if scheme_name_exclude_patterns:
        d["scheme_name_exclude_patterns"] = scheme_name_exclude_patterns

    if test:
        d["test_options"] = [
            test.test_options.app_language or "",
            test.test_options.app_region or "",
            test.test_options.code_coverage or "",
        ]

    return d

# API

xcschemes = struct(
    arg = _arg,
    autogeneration = struct(
        test = _autogeneration_test,
    ),
    autogeneration_config = _autogeneration_config,
    diagnostics = _diagnostics,
    env_value = _env_value,
    launch_path = _launch_path,
    launch_target = _launch_target,
    library_target = _library_target,
    pre_post_actions = _pre_post_actions,
    profile = _profile,
    run = _run,
    scheme = _scheme,
    test = _test,
    test_options = _test_options,
    test_target = _test_target,
    top_level_anchor_target = _top_level_anchor_target,
    top_level_build_target = _top_level_build_target,
)
