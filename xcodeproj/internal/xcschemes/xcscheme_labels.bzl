"""Module for dealing with custom Xcode schemes from the `xcodeproj` macro."""

load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "FALSE_ARG",
    "TRUE_ARG",
)

def _resolve_build_target_labels(build_target):
    if type(build_target) == "string":
        return _resolve_label(build_target)

    return struct(
        extension_host = _resolve_label(build_target.extension_host),
        include = build_target.include,
        label = _resolve_label(build_target.label),
        library_targets = [
            _resolve_library_target_labels(library_target)
            for library_target in build_target.library_targets
        ],
        post_actions = build_target.post_actions,
        pre_actions = build_target.pre_actions,
        target_environment = build_target.target_environment,
    )

def _resolve_label(label_str):
    if not label_str:
        return ""

    return str(native.package_relative_label(label_str))

def _resolve_labels(schemes):
    return [
        _resolve_scheme_labels(scheme)
        for scheme in schemes
    ]

def _resolve_launch_target_labels(launch_target):
    if not launch_target or type(launch_target) == "string":
        return _resolve_label(launch_target)

    if launch_target.is_path == TRUE_ARG:
        return struct(
            is_path = TRUE_ARG,
            path = launch_target.path,
            post_actions = launch_target.post_actions,
            pre_actions = launch_target.pre_actions,
            working_directory = launch_target.working_directory,
        )

    return struct(
        extension_host = _resolve_label(launch_target.extension_host),
        is_path = FALSE_ARG,
        label = _resolve_label(launch_target.label),
        library_targets = [
            _resolve_library_target_labels(library_target)
            for library_target in launch_target.library_targets
        ],
        post_actions = launch_target.post_actions,
        pre_actions = launch_target.pre_actions,
        target_environment = launch_target.target_environment,
        working_directory = launch_target.working_directory,
    )

def _resolve_library_target_labels(library_target):
    if type(library_target) == "string":
        return _resolve_label(library_target)

    return struct(
        label = _resolve_label(library_target.label),
        post_actions = library_target.post_actions,
        pre_actions = library_target.pre_actions,
    )

def _resolve_scheme_labels(scheme):
    return struct(
        name = scheme.name,
        profile = _resolve_profile_labels(scheme.profile),
        run = _resolve_run_labels(scheme.run),
        test = _resolve_test_labels(scheme.test),
    )

def _resolve_profile_labels(profile):
    if not profile or profile == "same_as_run":
        return profile

    return struct(
        args = profile.args,
        build_targets = [
            _resolve_build_target_labels(build_target)
            for build_target in profile.build_targets
        ],
        env = profile.env,
        env_include_defaults = profile.env_include_defaults,
        launch_target = _resolve_launch_target_labels(profile.launch_target),
        use_run_args_and_env = profile.use_run_args_and_env,
        xcode_configuration = profile.xcode_configuration,
    )

def _resolve_run_labels(run):
    if not run:
        return None

    return struct(
        args = run.args,
        build_targets = [
            _resolve_build_target_labels(build_target)
            for build_target in run.build_targets
        ],
        diagnostics = run.diagnostics,
        env = run.env,
        env_include_defaults = run.env_include_defaults,
        launch_target = _resolve_launch_target_labels(run.launch_target),
        xcode_configuration = run.xcode_configuration,
    )

def _resolve_test_labels(test):
    if not test:
        return None

    return struct(
        args = test.args,
        build_targets = [
            _resolve_build_target_labels(build_target)
            for build_target in test.build_targets
        ],
        diagnostics = test.diagnostics,
        env = test.env,
        env_include_defaults = test.env_include_defaults,
        options = test.options,
        test_targets = [
            _resolve_test_target_labels(test_target)
            for test_target in test.test_targets
        ],
        use_run_args_and_env = test.use_run_args_and_env,
        xcode_configuration = test.xcode_configuration,
    )

def _resolve_test_target_labels(test_target):
    if type(test_target) == "string":
        return _resolve_label(test_target)

    return struct(
        enabled = test_target.enabled,
        label = _resolve_label(test_target.label),
        library_targets = [
            _resolve_library_target_labels(library_target)
            for library_target in test_target.library_targets
        ],
        post_actions = test_target.post_actions,
        pre_actions = test_target.pre_actions,
        target_environment = test_target.target_environment,
    )

xcscheme_labels = struct(
    resolve_labels = _resolve_labels,
)
