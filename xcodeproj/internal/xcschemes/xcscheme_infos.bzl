"""Module for parsing macro custom Xcode schemes json in the analysis phase."""

load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_LIST",
    "EMPTY_STRING",
    "FALSE_ARG",
    "TRUE_ARG",
)

# Constructors

def _make_arg(value, *, enabled = TRUE_ARG, literal_string = TRUE_ARG):
    return struct(
        enabled = enabled,
        literal_string = literal_string,
        value = value,
    )

def _make_env(value, *, enabled = TRUE_ARG):
    return struct(
        enabled = enabled,
        value = value,
    )

def _make_build_target(
        id,
        *,
        post_actions = EMPTY_LIST,
        pre_actions = EMPTY_LIST):
    return struct(
        id = id,
        post_actions = post_actions,
        pre_actions = pre_actions,
    )

def _make_diagnostics(
        *,
        address_sanitizer = FALSE_ARG,
        thread_sanitizer = FALSE_ARG,
        undefined_behavior_sanitizer = FALSE_ARG,
        main_thread_checker = TRUE_ARG,
        thread_performance_checker = TRUE_ARG):
    return struct(
        address_sanitizer = address_sanitizer,
        thread_sanitizer = thread_sanitizer,
        undefined_behavior_sanitizer = undefined_behavior_sanitizer,
        main_thread_checker = main_thread_checker,
        thread_performance_checker = thread_performance_checker,
    )

def _make_test_options(
        *,
        app_region = EMPTY_STRING,
        app_language = EMPTY_STRING,
        code_coverage = FALSE_ARG):
    return struct(
        app_region = app_region,
        app_language = app_language,
        code_coverage = code_coverage,
    )

def _make_launch_target(
        id = EMPTY_STRING,
        *,
        extension_host = EMPTY_STRING,
        path = None,
        post_actions = EMPTY_LIST,
        pre_actions = EMPTY_LIST,
        working_directory = EMPTY_STRING):
    if path:
        return struct(
            is_path = TRUE_ARG,
            path = path,
            post_actions = post_actions,
            pre_actions = pre_actions,
            working_directory = working_directory,
        )

    return struct(
        extension_host = extension_host,
        id = id,
        is_path = FALSE_ARG,
        post_actions = post_actions,
        pre_actions = pre_actions,
        working_directory = working_directory,
    )

def _make_same_as_run_launch_target(run_launch_target):
    if run_launch_target.is_path == TRUE_ARG:
        return struct(
            is_path = TRUE_ARG,
            path = run_launch_target.path,
            post_actions = EMPTY_LIST,
            pre_actions = EMPTY_LIST,
            working_directory = run_launch_target.working_directory,
        )

    return struct(
        extension_host = run_launch_target.extension_host,
        id = run_launch_target.id,
        is_path = run_launch_target.is_path,
        post_actions = EMPTY_LIST,
        pre_actions = EMPTY_LIST,
        working_directory = run_launch_target.working_directory,
    )

def _make_pre_post_action(
        *,
        for_build,
        order,
        script_text,
        title):
    return struct(
        for_build = for_build,
        order = order,
        script_text = script_text,
        title = title,
    )

def _make_profile(
        *,
        args = None,
        build_targets = EMPTY_LIST,
        env = None,
        env_include_defaults = FALSE_ARG,
        launch_target = _make_launch_target(),
        use_run_args_and_env = TRUE_ARG,
        xcode_configuration = EMPTY_STRING):
    return struct(
        args = args,
        build_targets = build_targets,
        env = env,
        env_include_defaults = env_include_defaults,
        launch_target = launch_target,
        use_run_args_and_env = use_run_args_and_env,
        xcode_configuration = xcode_configuration,
    )

def _make_run(
        *,
        args = None,
        build_targets = EMPTY_LIST,
        diagnostics = _make_diagnostics(),
        env = None,
        env_include_defaults = TRUE_ARG,
        launch_target = _make_launch_target(),
        xcode_configuration = EMPTY_STRING):
    return struct(
        args = args,
        build_targets = build_targets,
        diagnostics = diagnostics,
        env = env,
        env_include_defaults = env_include_defaults,
        launch_target = launch_target,
        xcode_configuration = xcode_configuration,
    )

def _make_test(
        *,
        args = None,
        build_targets = EMPTY_LIST,
        diagnostics = _make_diagnostics(),
        env = None,
        env_include_defaults = FALSE_ARG,
        options = _make_test_options(),
        test_targets = EMPTY_LIST,
        use_run_args_and_env = TRUE_ARG,
        xcode_configuration = EMPTY_STRING):
    return struct(
        args = args,
        build_targets = build_targets,
        diagnostics = diagnostics,
        env = env,
        env_include_defaults = env_include_defaults,
        options = options,
        test_targets = test_targets,
        use_run_args_and_env = use_run_args_and_env,
        xcode_configuration = xcode_configuration,
    )

def _make_test_target(
        id,
        *,
        enabled = TRUE_ARG,
        post_actions = EMPTY_LIST,
        pre_actions = EMPTY_LIST):
    return struct(
        enabled = enabled,
        id = id,
        post_actions = post_actions,
        pre_actions = pre_actions,
    )

def _make_scheme(
        name,
        *,
        profile = _make_profile(),
        run = _make_run(),
        test = _make_test()):
    return struct(
        name = name,
        profile = profile,
        run = run,
        test = test,
    )

# JSON

def _arg_info_from_dict(arg):
    if type(arg) == "string":
        return _make_arg(
            value = arg,
        )

    return _make_arg(
        enabled = arg["enabled"],
        literal_string = arg["literal_string"],
        value = arg["value"],
    )

def _env_info_from_dict(env):
    if type(env) == "string":
        return _make_env(
            value = env,
        )

    return _make_env(
        enabled = env["enabled"],
        value = env["value"],
    )

def _arg_infos_from_list(args):
    if args == "inherit":
        return None
    return [_arg_info_from_dict(arg) for arg in args]

def _build_target_infos_from_dict(
        build_target,
        *,
        scheme_name,
        top_level_deps,
        xcode_configuration):
    if type(build_target) == "string":
        return [
            _make_build_target(
                id = _get_top_level_id(
                    label = build_target,
                    scheme_name = scheme_name,
                    target_environment = None,
                    top_level_deps = top_level_deps,
                    xcode_configuration = xcode_configuration,
                ),
            ),
        ]

    deps_for_top_level_target = _get_deps_for_top_level_target(
        label = build_target["label"],
        scheme_name = scheme_name,
        target_environment = build_target["target_environment"],
        top_level_deps = top_level_deps,
        xcode_configuration = xcode_configuration,
    )

    if build_target["include"]:
        build_targets = [
            _make_build_target(
                id = deps_for_top_level_target.id,
                post_actions = _pre_post_action_info_from_dicts(
                    build_target["post_actions"],
                ),
                pre_actions = _pre_post_action_info_from_dicts(
                    build_target["pre_actions"],
                ),
            ),
        ]
    else:
        build_targets = []

    build_targets.extend([
        _library_target_info_from_dict(
            library_target,
            scheme_name = scheme_name,
            target_ids = deps_for_top_level_target.deps,
        )
        for library_target in build_target["library_targets"]
    ])

    return build_targets

def _diagnostics_info_from_dict(diagnostics):
    if not diagnostics:
        return _make_diagnostics()

    return _make_diagnostics(
        # Sanitizers
        address_sanitizer = diagnostics["address_sanitizer"],
        thread_sanitizer = diagnostics["thread_sanitizer"],
        undefined_behavior_sanitizer = (
            diagnostics["undefined_behavior_sanitizer"]
        ),

        # Checks
        main_thread_checker = diagnostics["main_thread_checker"],
        thread_performance_checker = (
            diagnostics["thread_performance_checker"]
        ),
    )

def _options_info_from_dict(options):
    if not options:
        return _make_test_options()

    return _make_test_options(
        app_region = options["app_region"],
        app_language = options["app_language"],
        code_coverage = options["code_coverage"],
    )

def _env_infos_from_dict(env):
    if env == "inherit":
        return None
    return {
        key: _env_info_from_dict(value)
        for key, value in env.items()
    }

def _get_library_target_id(label, *, scheme_name, target_ids):
    target_id = target_ids.get(label)
    if not target_id:
        fail(
            """\
Unknown library target in `xcscheme` "{scheme}": {label}

Is '{label}' an `alias` target? Only actual target labels are supported in \
`xcscheme` definitions. Check that '{label}' is spelled correctly, and if it \
is, make sure it's a transitive dependency of a top-level target in the \
`xcodeproj.top_level_targets` attribute.
""".format(label = label, scheme = scheme_name),
        )

    return target_id

def _get_deps_for_top_level_target(
        *,
        scheme_name,
        target_environment,
        top_level_deps,
        label,
        xcode_configuration):
    if not target_environment:
        if "simulator" in top_level_deps:
            target_environment = "simulator"
        else:
            target_environment = "device"
    target_ids_by_configuration = top_level_deps.get(target_environment)
    if not target_ids_by_configuration:
        fail(
            """\
Unknown target environment in `xcscheme` "{scheme}": {env}
""".format(env = target_environment, scheme = scheme_name),
        )

    target_ids_by_label = target_ids_by_configuration.get(xcode_configuration)
    if not target_ids_by_label:
        fail(
            """\
Unknown Xcode configuration in `xcscheme` "{scheme}": {config}
""".format(config = xcode_configuration, scheme = scheme_name),
        )

    target_ids = target_ids_by_label.get(label)
    if not target_ids:
        fail(
            """\
Unknown top-level target in `xcscheme` "{scheme}": {label}

Is '{label}' an `alias` target? Only actual target labels are supported in \
`xcscheme` definitions. Check that '{label}' is spelled correctly, and if it \
is, make sure it's in the `xcodeproj.top_level_targets` attribute.
""".format(label = label, scheme = scheme_name),
        )

    return target_ids

def _get_top_level_id(
        *,
        label,
        scheme_name,
        target_environment,
        top_level_deps,
        xcode_configuration):
    deps_for_top_level_target = _get_deps_for_top_level_target(
        label = label,
        scheme_name = scheme_name,
        target_environment = target_environment,
        top_level_deps = top_level_deps,
        xcode_configuration = xcode_configuration,
    )
    return deps_for_top_level_target.id

def _launch_target_info_from_dict(
        launch_target,
        *,
        scheme_name,
        top_level_deps,
        xcode_configuration):
    if not launch_target:
        return (
            _make_launch_target(),
            EMPTY_LIST,
        )

    if type(launch_target) == "string":
        return (
            _make_launch_target(
                id = _get_top_level_id(
                    label = launch_target,
                    scheme_name = scheme_name,
                    target_environment = None,
                    top_level_deps = top_level_deps,
                    xcode_configuration = xcode_configuration,
                ),
            ),
            EMPTY_LIST,
        )

    if launch_target["is_path"] == TRUE_ARG:
        return (
            _make_launch_target(
                path = launch_target["path"],
                post_actions = _pre_post_action_info_from_dicts(
                    launch_target["post_actions"],
                ),
                pre_actions = _pre_post_action_info_from_dicts(
                    launch_target["pre_actions"],
                ),
                working_directory = launch_target["working_directory"],
            ),
            EMPTY_LIST,
        )

    deps_for_top_level_target = _get_deps_for_top_level_target(
        label = launch_target["label"],
        scheme_name = scheme_name,
        target_environment = launch_target["target_environment"],
        top_level_deps = top_level_deps,
        xcode_configuration = xcode_configuration,
    )

    extension_host_label = launch_target["extension_host"]
    if extension_host_label:
        extension_host = _get_top_level_id(
            label = extension_host_label,
            scheme_name = scheme_name,
            target_environment = launch_target["target_environment"],
            top_level_deps = top_level_deps,
            xcode_configuration = xcode_configuration,
        )
    else:
        extension_host = EMPTY_STRING

    launch_target_info = _make_launch_target(
        extension_host = extension_host,
        id = deps_for_top_level_target.id,
        post_actions = _pre_post_action_info_from_dicts(
            launch_target["post_actions"],
        ),
        pre_actions = _pre_post_action_info_from_dicts(
            launch_target["pre_actions"],
        ),
        working_directory = launch_target["working_directory"],
    )

    library_targets = [
        _library_target_info_from_dict(
            library_target,
            scheme_name = scheme_name,
            target_ids = deps_for_top_level_target.deps,
        )
        for library_target in launch_target["library_targets"]
    ]

    return (launch_target_info, library_targets)

def _library_target_info_from_dict(
        library_target,
        *,
        scheme_name,
        target_ids):
    if type(library_target) == "string":
        return _make_build_target(
            id = _get_library_target_id(
                library_target,
                scheme_name = scheme_name,
                target_ids = target_ids,
            ),
        )

    return _make_build_target(
        id = _get_library_target_id(
            library_target["label"],
            scheme_name = scheme_name,
            target_ids = target_ids,
        ),
        post_actions = _pre_post_action_info_from_dicts(
            library_target["post_actions"],
        ),
        pre_actions = _pre_post_action_info_from_dicts(
            library_target["pre_actions"],
        ),
    )

def _pre_post_action_info_from_dict(pre_post_action):
    return _make_pre_post_action(
        for_build = pre_post_action["for_build"],
        order = pre_post_action["order"],
        script_text = pre_post_action["script_text"],
        title = pre_post_action["title"],
    )

def _pre_post_action_info_from_dicts(pre_post_actions):
    return [
        _pre_post_action_info_from_dict(pre_post_action)
        for pre_post_action in pre_post_actions
    ]

def _profile_info_from_dict(
        profile,
        *,
        default_xcode_configuration,
        run,
        scheme_name,
        top_level_deps):
    if profile == "same_as_run":
        return _make_profile(
            build_targets = run.build_targets,
            launch_target = _make_same_as_run_launch_target(
                run.launch_target,
            ),
        )

    if not profile:
        return _make_profile()

    xcode_configuration = profile["xcode_configuration"]

    resolving_xcode_configuration = (
        xcode_configuration or
        default_xcode_configuration
    )

    build_targets = []
    (launch_target, launch_build_targets) = _launch_target_info_from_dict(
        profile["launch_target"],
        scheme_name = scheme_name,
        top_level_deps = top_level_deps,
        xcode_configuration = resolving_xcode_configuration,
    )
    build_targets.extend(launch_build_targets)

    build_targets.extend([
        info
        for build_target in profile["build_targets"]
        for info in _build_target_infos_from_dict(
            build_target,
            scheme_name = scheme_name,
            top_level_deps = top_level_deps,
            xcode_configuration = resolving_xcode_configuration,
        )
    ])

    return _make_profile(
        args = _arg_infos_from_list(profile["args"]),
        build_targets = build_targets,
        env = _env_infos_from_dict(profile["env"]),
        env_include_defaults = profile["env_include_defaults"],
        launch_target = launch_target,
        use_run_args_and_env = profile["use_run_args_and_env"],
        xcode_configuration = xcode_configuration,
    )

def _run_info_from_dict(
        run,
        *,
        default_xcode_configuration,
        scheme_name,
        top_level_deps):
    if not run:
        return _make_run()

    xcode_configuration = run["xcode_configuration"]
    resolving_xcode_configuration = (
        xcode_configuration or
        default_xcode_configuration
    )

    build_targets = []
    (launch_target, launch_build_targets) = _launch_target_info_from_dict(
        run["launch_target"],
        scheme_name = scheme_name,
        top_level_deps = top_level_deps,
        xcode_configuration = resolving_xcode_configuration,
    )
    build_targets.extend(launch_build_targets)

    build_targets.extend([
        info
        for build_target in run["build_targets"]
        for info in _build_target_infos_from_dict(
            build_target,
            scheme_name = scheme_name,
            top_level_deps = top_level_deps,
            xcode_configuration = resolving_xcode_configuration,
        )
    ])

    return _make_run(
        args = _arg_infos_from_list(run["args"]),
        build_targets = build_targets,
        diagnostics = _diagnostics_info_from_dict(run["diagnostics"]),
        env = _env_infos_from_dict(run["env"]),
        env_include_defaults = run["env_include_defaults"],
        launch_target = launch_target,
        xcode_configuration = xcode_configuration,
    )

def _test_info_from_dict(
        test,
        *,
        default_xcode_configuration,
        scheme_name,
        top_level_deps):
    if not test:
        return _make_test()

    xcode_configuration = test["xcode_configuration"]
    resolving_xcode_configuration = (
        xcode_configuration or
        default_xcode_configuration
    )

    build_targets = []
    test_targets = []
    for test_target in test["test_targets"]:
        (test_target, test_build_targets) = _test_target_info_from_dict(
            test_target,
            scheme_name = scheme_name,
            top_level_deps = top_level_deps,
            xcode_configuration = resolving_xcode_configuration,
        )
        build_targets.extend(test_build_targets)
        test_targets.append(test_target)

    build_targets.extend([
        info
        for build_target in test["build_targets"]
        for info in _build_target_infos_from_dict(
            build_target,
            scheme_name = scheme_name,
            top_level_deps = top_level_deps,
            xcode_configuration = resolving_xcode_configuration,
        )
    ])

    return _make_test(
        args = _arg_infos_from_list(test["args"]),
        build_targets = build_targets,
        diagnostics = _diagnostics_info_from_dict(test["diagnostics"]),
        env = _env_infos_from_dict(test["env"]),
        env_include_defaults = test["env_include_defaults"],
        options = _options_info_from_dict(test["options"]),
        test_targets = test_targets,
        use_run_args_and_env = test["use_run_args_and_env"],
        xcode_configuration = xcode_configuration,
    )

def _test_target_info_from_dict(
        test_target,
        *,
        scheme_name,
        top_level_deps,
        xcode_configuration):
    if type(test_target) == "string":
        return (
            _make_test_target(
                enabled = TRUE_ARG,
                id = _get_top_level_id(
                    label = test_target,
                    scheme_name = scheme_name,
                    target_environment = None,
                    top_level_deps = top_level_deps,
                    xcode_configuration = xcode_configuration,
                ),
                post_actions = EMPTY_LIST,
                pre_actions = EMPTY_LIST,
            ),
            EMPTY_LIST,
        )

    deps_for_top_level_target = _get_deps_for_top_level_target(
        label = test_target["label"],
        scheme_name = scheme_name,
        target_environment = test_target["target_environment"],
        top_level_deps = top_level_deps,
        xcode_configuration = xcode_configuration,
    )

    test_target_info = _make_test_target(
        enabled = test_target["enabled"],
        id = deps_for_top_level_target.id,
        post_actions = _pre_post_action_info_from_dicts(
            test_target["post_actions"],
        ),
        pre_actions = _pre_post_action_info_from_dicts(
            test_target["pre_actions"],
        ),
    )

    library_targets = [
        _library_target_info_from_dict(
            library_target,
            scheme_name = scheme_name,
            target_ids = deps_for_top_level_target.deps,
        )
        for library_target in test_target["library_targets"]
    ]

    return (test_target_info, library_targets)

def _scheme_info_from_dict(
        scheme,
        *,
        default_xcode_configuration,
        top_level_deps):
    name = scheme["name"]

    run = _run_info_from_dict(
        scheme["run"],
        default_xcode_configuration = default_xcode_configuration,
        scheme_name = name,
        top_level_deps = top_level_deps,
    )

    return _make_scheme(
        name = name,
        profile = _profile_info_from_dict(
            scheme["profile"],
            default_xcode_configuration = default_xcode_configuration,
            scheme_name = name,
            run = run,
            top_level_deps = top_level_deps,
        ),
        run = run,
        test = _test_info_from_dict(
            scheme["test"],
            default_xcode_configuration = default_xcode_configuration,
            scheme_name = name,
            top_level_deps = top_level_deps,
        ),
    )

# API

def _from_json(json_str, *, default_xcode_configuration, top_level_deps):
    return [
        _scheme_info_from_dict(
            scheme,
            default_xcode_configuration = default_xcode_configuration,
            top_level_deps = top_level_deps,
        )
        for scheme in json.decode(json_str)
    ]

xcscheme_infos = struct(
    from_json = _from_json,
)

# These functions are exposed only for access in unit tests
xcscheme_infos_testable = struct(
    make_arg = _make_arg,
    make_build_target = _make_build_target,
    make_env = _make_env,
    make_diagnostics = _make_diagnostics,
    make_launch_target = _make_launch_target,
    make_test_options = _make_test_options,
    make_pre_post_action = _make_pre_post_action,
    make_profile = _make_profile,
    make_run = _make_run,
    make_scheme = _make_scheme,
    make_test = _make_test,
    make_test_target = _make_test_target,
)
