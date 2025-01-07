"""Tests for `xcschemes_infos.from_json`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":utils.bzl", "json_to_xcscheme_infos")

# buildifier: disable=bzl-visibility
# buildifier: disable=out-of-order-load
load(
    "//xcodeproj/internal/xcschemes:xcscheme_infos.bzl",
    "xcscheme_infos",
    "xcscheme_infos_testable",
)

# Utility

def _json_to_top_level_deps(json_str):
    return {
        target_environment: {
            xcode_configuration: {
                label: struct(
                    id = d["id"],
                    deps = d["deps"],
                )
                for label, d in d.items()
            }
            for xcode_configuration, d in d.items()
        }
        for target_environment, d in json.decode(json_str).items()
    }

# Tests

def _infos_from_json_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    expected_infos = json_to_xcscheme_infos(ctx.attr.expected_infos)

    # Act

    infos = xcscheme_infos.from_json(
        ctx.attr.json_str,
        default_xcode_configuration = ctx.attr.default_xcode_configuration,
        top_level_deps = _json_to_top_level_deps(ctx.attr.top_level_deps),
    )

    # Assert

    asserts.equals(
        env,
        expected_infos,
        infos,
        "infos",
    )

    return unittest.end(env)

infos_from_json_test = unittest.make(
    impl = _infos_from_json_test_impl,
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "default_xcode_configuration": attr.string(mandatory = True),
        "json_str": attr.string(mandatory = True),
        "top_level_deps": attr.string(mandatory = True),

        # Expected
        "expected_infos": attr.string(mandatory = True),
    },
)

def infos_from_json_test_suite(name):
    """Test suite for `xcscheme_infos.from_json`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    # buildifier: disable=uninitialized
    def _add_test(
            *,
            name,

            # Inputs
            default_xcode_configuration,
            json_str,
            top_level_deps,

            # Expected
            expected_infos):
        test_names.append(name)
        infos_from_json_test(
            name = name,

            # Inputs
            default_xcode_configuration = default_xcode_configuration,
            json_str = json_str,
            top_level_deps = json.encode(top_level_deps),

            # Expected
            expected_infos = json.encode(expected_infos),
        )

    top_level_deps = {
        "device": {
            "custom": {
                "bt 4 label": struct(
                    id = "device bt 4",
                    deps = {"lib label": "device bt 4 lib"},
                ),
                "eh label": struct(id = "device eh", deps = {}),
                "lt label": struct(
                    id = "device lt",
                    deps = {"lib label": "device lt lib"},
                ),
                "tt 1 label": struct(id = "device tt 1", deps = {}),
                "tt 2 label": struct(
                    id = "device tt 2",
                    deps = {"lib label": "device tt 2 lib"},
                ),
            },
        },
        "simulator": {
            "custom": {
                "bt 1 label": struct(id = "sim bt 1", deps = {}),
                "bt 2 label": struct(
                    id = "sim bt 2",
                    deps = {"lib label": "sim bt 2 lib"},
                ),
                "bt 3 label": struct(id = "sim bt 3", deps = {}),
                "bt 4 label": struct(
                    id = "sim bt 4",
                    deps = {"lib label": "sim bt 4 lib"},
                ),
                "eh label": struct(id = "sim eh", deps = {}),
                "lt label": struct(
                    id = "sim lt",
                    deps = {"lib label": "sim lt lib"},
                ),
                "tt 1 label": struct(id = "sim tt 1", deps = {}),
                "tt 2 label": struct(
                    id = "sim tt 2",
                    deps = {"lib label": "sim tt 2 lib"},
                ),
            },
        },
    }

    full_args = [
        "-a\nnewline",
        xcscheme_infos_testable.make_arg(
            "B",
            literal_string = "0",
            enabled = "0",
        ),
    ]
    expected_full_args = [
        xcscheme_infos_testable.make_arg("-a\nnewline"),
        xcscheme_infos_testable.make_arg(
            "B",
            literal_string = "0",
            enabled = "0",
        ),
    ]

    full_env = {
        "A": "B",
        "ENV\nVAR": xcscheme_infos_testable.make_env(
            "1\n2",
            enabled = "0",
        ),
    }
    expected_full_env = {
        "A": xcscheme_infos_testable.make_env("B"),
        "ENV\nVAR": xcscheme_infos_testable.make_env(
            "1\n2",
            enabled = "0",
        ),
    }

    full_build_targets = [
        struct(
            include = False,
            label = "bt 2 label",
            library_targets = [
                struct(
                    label = "lib label",
                    post_actions = [],
                    pre_actions = [],
                ),
            ],
            post_actions = ["won't be parsed"],
            pre_actions = ["won't be parsed"],
            target_environment = "",
        ),
        "bt 3 label",
        struct(
            include = True,
            label = "bt 4 label",
            library_targets = [
                struct(
                    label = "lib label",
                    post_actions = [
                        xcscheme_infos_testable.make_pre_post_action(
                            for_build = True,
                            order = "1",
                            script_text = "lib\nscript",
                            title = "lib title",
                        ),
                    ],
                    pre_actions = [
                        xcscheme_infos_testable.make_pre_post_action(
                            for_build = False,
                            order = "2",
                            script_text = "lib script",
                            title = "lib\ntitle",
                        ),
                    ],
                ),
            ],
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "bt 4 script",
                    title = "bt 4 script title",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "bt 4 script",
                    title = "bt 4 script title",
                ),
            ],
            target_environment = "device",
        ),
    ]
    expected_full_build_targets = [
        xcscheme_infos_testable.make_build_target(
            "sim bt 2 lib",
        ),
        xcscheme_infos_testable.make_build_target("sim bt 3"),
        xcscheme_infos_testable.make_build_target(
            id = "device bt 4",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "bt 4 script",
                    title = "bt 4 script title",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "bt 4 script",
                    title = "bt 4 script title",
                ),
            ],
        ),
        xcscheme_infos_testable.make_build_target(
            id = "device bt 4 lib",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "1",
                    script_text = "lib\nscript",
                    title = "lib title",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "2",
                    script_text = "lib script",
                    title = "lib\ntitle",
                ),
            ],
        ),
    ]

    full_launch_target = struct(
        extension_host = "eh label",
        is_path = "0",
        label = "lt label",
        library_targets = [
            struct(
                label = "lib label",
                post_actions = [
                    xcscheme_infos_testable.make_pre_post_action(
                        for_build = True,
                        order = "",
                        script_text = "ssss",
                        title = "ttt",
                    ),
                ],
                pre_actions = [
                    xcscheme_infos_testable.make_pre_post_action(
                        for_build = True,
                        order = "7",
                        script_text = "s",
                        title = "tttt",
                    ),
                ],
            ),
        ],
        post_actions = [
            xcscheme_infos_testable.make_pre_post_action(
                for_build = True,
                order = "7",
                script_text = "s",
                title = "t",
            ),
        ],
        pre_actions = [
            xcscheme_infos_testable.make_pre_post_action(
                for_build = False,
                order = "42",
                script_text = "sss",
                title = "tt",
            ),
        ],
        target_environment = "device",
        working_directory = "wd",
    )
    expected_full_launch_target = xcscheme_infos_testable.make_launch_target(
        extension_host = "device eh",
        id = "device lt",
        post_actions = [
            xcscheme_infos_testable.make_pre_post_action(
                for_build = True,
                order = "7",
                script_text = "s",
                title = "t",
            ),
        ],
        pre_actions = [
            xcscheme_infos_testable.make_pre_post_action(
                for_build = False,
                order = "42",
                script_text = "sss",
                title = "tt",
            ),
        ],
        working_directory = "wd",
    )
    expected_profile_same_as_run_launch_target = (
        xcscheme_infos_testable.make_launch_target(
            extension_host = "device eh",
            id = "device lt",
            post_actions = [],
            pre_actions = [],
            working_directory = "wd",
        )
    )
    expected_full_launch_build_targets = [
        xcscheme_infos_testable.make_build_target(
            id = "device lt lib",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "",
                    script_text = "ssss",
                    title = "ttt",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "7",
                    script_text = "s",
                    title = "tttt",
                ),
            ],
        ),
    ]

    # Empty

    _add_test(
        name = "{}_empty".format(name),

        # Inputs
        default_xcode_configuration = "AppStore",
        json_str = json.encode([]),
        top_level_deps = {},

        # Expected
        expected_infos = [],
    )

    # Minimal

    _add_test(
        name = "{}_minimal".format(name),

        # Inputs
        default_xcode_configuration = "AppStore",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": None,
                "run": None,
                "test": None,
            },
            {
                "name": "another Scheme",
                "profile": None,
                "run": None,
                "test": None,
            },
        ]),
        top_level_deps = {},

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
            ),
            xcscheme_infos_testable.make_scheme(
                name = "another Scheme",
            ),
        ],
    )

    # Profile

    _add_test(
        name = "{}_profile_fallback_xcode_configuration".format(name),

        # Inputs
        default_xcode_configuration = "custom",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": struct(
                    args = "inherit",
                    build_targets = [
                        "bt 1 label",
                        struct(
                            include = True,
                            label = "bt 4 label",
                            library_targets = [
                                struct(
                                    label = "lib label",
                                    post_actions = [],
                                    pre_actions = [],
                                ),
                            ],
                            post_actions = [],
                            pre_actions = [],
                            target_environment = "",
                        ),
                    ],
                    env = "inherit",
                    env_include_defaults = "0",
                    launch_target = struct(
                        extension_host = "eh label",
                        label = "lt label",
                        library_targets = [
                            struct(
                                label = "lib label",
                                post_actions = [],
                                pre_actions = [],
                            ),
                        ],
                        post_actions = [],
                        pre_actions = [],
                        target_environment = "",
                        working_directory = "",
                        is_path = "0",
                    ),
                    use_run_args_and_env = "1",
                    xcode_configuration = "",
                ),
                "run": None,
                "test": None,
            },
        ]),
        top_level_deps = top_level_deps,

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
                profile = xcscheme_infos_testable.make_profile(
                    build_targets = [
                        xcscheme_infos_testable.make_build_target("sim lt lib"),
                        xcscheme_infos_testable.make_build_target("sim bt 1"),
                        xcscheme_infos_testable.make_build_target("sim bt 4"),
                        xcscheme_infos_testable.make_build_target(
                            "sim bt 4 lib",
                        ),
                    ],
                    launch_target = xcscheme_infos_testable.make_launch_target(
                        extension_host = "sim eh",
                        id = "sim lt",
                    ),
                ),
            ),
        ],
    )

    _add_test(
        name = "{}_profile_full".format(name),

        # Inputs
        default_xcode_configuration = "AppStore",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": struct(
                    args = full_args,
                    build_targets = full_build_targets,
                    env = full_env,
                    env_include_defaults = "1",
                    launch_target = full_launch_target,
                    use_run_args_and_env = "0",
                    xcode_configuration = "custom",
                ),
                "run": None,
                "test": None,
            },
        ]),
        top_level_deps = top_level_deps,

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
                profile = xcscheme_infos_testable.make_profile(
                    args = expected_full_args,
                    build_targets = (
                        expected_full_launch_build_targets +
                        expected_full_build_targets
                    ),
                    env = expected_full_env,
                    env_include_defaults = "1",
                    launch_target = expected_full_launch_target,
                    use_run_args_and_env = "0",
                    xcode_configuration = "custom",
                ),
            ),
        ],
    )

    _add_test(
        name = "{}_profile_same_as_run_none".format(name),

        # Inputs
        default_xcode_configuration = "AppStore",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": "same_as_run",
                "run": None,
                "test": None,
            },
        ]),
        top_level_deps = {},

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
                profile = xcscheme_infos_testable.make_profile(),
            ),
        ],
    )

    _add_test(
        name = "{}_profile_same_as_run_not_none".format(name),

        # Inputs
        default_xcode_configuration = "AppStore",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": "same_as_run",
                "run": struct(
                    args = ["-v"],
                    build_targets = full_build_targets,
                    diagnostics = xcscheme_infos_testable.make_diagnostics(
                        address_sanitizer = "1",
                    ),
                    env = {"A": "B"},
                    env_include_defaults = "1",
                    launch_target = full_launch_target,
                    xcode_configuration = "custom",
                ),
                "test": None,
            },
        ]),
        top_level_deps = top_level_deps,

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
                profile = xcscheme_infos_testable.make_profile(
                    build_targets = (
                        expected_full_launch_build_targets +
                        expected_full_build_targets
                    ),
                    env_include_defaults = "0",
                    launch_target = expected_profile_same_as_run_launch_target,
                    use_run_args_and_env = "1",
                ),
                run = xcscheme_infos_testable.make_run(
                    args = [xcscheme_infos_testable.make_arg("-v")],
                    build_targets = (
                        expected_full_launch_build_targets +
                        expected_full_build_targets
                    ),
                    diagnostics = xcscheme_infos_testable.make_diagnostics(
                        address_sanitizer = "1",
                    ),
                    env = {"A": xcscheme_infos_testable.make_env("B")},
                    env_include_defaults = "1",
                    launch_target = expected_full_launch_target,
                    xcode_configuration = "custom",
                ),
            ),
        ],
    )

    # Run

    _add_test(
        name = "{}_run_fallback_xcode_configuration".format(name),

        # Inputs
        default_xcode_configuration = "custom",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": None,
                "run": struct(
                    args = "inherit",
                    build_targets = [
                        "bt 1 label",
                        struct(
                            include = True,
                            label = "bt 4 label",
                            library_targets = [
                                struct(
                                    label = "lib label",
                                    post_actions = [],
                                    pre_actions = [],
                                ),
                            ],
                            post_actions = [],
                            pre_actions = [],
                            target_environment = "",
                        ),
                    ],
                    diagnostics = None,
                    env = "inherit",
                    env_include_defaults = "1",
                    launch_target = struct(
                        extension_host = "eh label",
                        is_path = "0",
                        label = "lt label",
                        library_targets = [
                            struct(
                                label = "lib label",
                                post_actions = [],
                                pre_actions = [],
                            ),
                        ],
                        post_actions = [],
                        pre_actions = [],
                        target_environment = "",
                        working_directory = "",
                    ),
                    xcode_configuration = "",
                ),
                "test": None,
            },
        ]),
        top_level_deps = top_level_deps,

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
                run = xcscheme_infos_testable.make_run(
                    build_targets = [
                        xcscheme_infos_testable.make_build_target("sim lt lib"),
                        xcscheme_infos_testable.make_build_target("sim bt 1"),
                        xcscheme_infos_testable.make_build_target("sim bt 4"),
                        xcscheme_infos_testable.make_build_target(
                            "sim bt 4 lib",
                        ),
                    ],
                    launch_target = xcscheme_infos_testable.make_launch_target(
                        extension_host = "sim eh",
                        id = "sim lt",
                    ),
                ),
            ),
        ],
    )

    expected_launch_path = xcscheme_infos_testable.make_launch_target(
        path = "/path/to/App.app",
        post_actions = [
            xcscheme_infos_testable.make_pre_post_action(
                for_build = True,
                order = "",
                script_text = "ssss",
                title = "ttt",
            ),
        ],
        pre_actions = [
            xcscheme_infos_testable.make_pre_post_action(
                for_build = True,
                order = "7",
                script_text = "s",
                title = "tttt",
            ),
        ],
        working_directory = "wd",
    )
    expected_profile_same_as_run_launch_path = (
        xcscheme_infos_testable.make_launch_target(
            path = "/path/to/App.app",
            post_actions = [],
            pre_actions = [],
            working_directory = "wd",
        )
    )

    _add_test(
        name = "{}_run_launch_path".format(name),

        # Inputs
        default_xcode_configuration = "AppStore",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": "same_as_run",
                "run": struct(
                    args = full_args,
                    build_targets = full_build_targets,
                    diagnostics = struct(
                        address_sanitizer = "1",
                        thread_sanitizer = "1",
                        undefined_behavior_sanitizer = "1",
                        main_thread_checker = "1",
                        thread_performance_checker = "1",
                    ),
                    env = full_env,
                    env_include_defaults = "0",
                    launch_target = struct(
                        is_path = "1",
                        path = "/path/to/App.app",
                        post_actions = [
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = True,
                                order = "",
                                script_text = "ssss",
                                title = "ttt",
                            ),
                        ],
                        pre_actions = [
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = True,
                                order = "7",
                                script_text = "s",
                                title = "tttt",
                            ),
                        ],
                        working_directory = "wd",
                    ),
                    xcode_configuration = "custom",
                ),
                "test": None,
            },
        ]),
        top_level_deps = top_level_deps,

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
                profile = xcscheme_infos_testable.make_profile(
                    build_targets = expected_full_build_targets,
                    env_include_defaults = "0",
                    launch_target = expected_profile_same_as_run_launch_path,
                ),
                run = xcscheme_infos_testable.make_run(
                    args = expected_full_args,
                    build_targets = expected_full_build_targets,
                    diagnostics = xcscheme_infos_testable.make_diagnostics(
                        address_sanitizer = "1",
                        thread_sanitizer = "1",
                        undefined_behavior_sanitizer = "1",
                        main_thread_checker = "1",
                        thread_performance_checker = "1",
                    ),
                    env = expected_full_env,
                    env_include_defaults = "0",
                    launch_target = expected_launch_path,
                    xcode_configuration = "custom",
                ),
            ),
        ],
    )

    _add_test(
        name = "{}_run_full".format(name),

        # Inputs
        default_xcode_configuration = "AppStore",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": None,
                "run": struct(
                    args = full_args,
                    build_targets = full_build_targets,
                    diagnostics = struct(
                        address_sanitizer = "1",
                        thread_sanitizer = "1",
                        undefined_behavior_sanitizer = "1",
                        main_thread_checker = "1",
                        thread_performance_checker = "1",
                    ),
                    env = full_env,
                    env_include_defaults = "0",
                    launch_target = full_launch_target,
                    use_run_args_and_env = "0",
                    xcode_configuration = "custom",
                ),
                "test": None,
            },
        ]),
        top_level_deps = top_level_deps,

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
                run = xcscheme_infos_testable.make_run(
                    args = expected_full_args,
                    build_targets = (
                        expected_full_launch_build_targets +
                        expected_full_build_targets
                    ),
                    diagnostics = xcscheme_infos_testable.make_diagnostics(
                        address_sanitizer = "1",
                        thread_sanitizer = "1",
                        undefined_behavior_sanitizer = "1",
                        main_thread_checker = "1",
                        thread_performance_checker = "1",
                    ),
                    env = expected_full_env,
                    env_include_defaults = "0",
                    launch_target = expected_full_launch_target,
                    xcode_configuration = "custom",
                ),
            ),
        ],
    )

    # Profile

    _add_test(
        name = "{}_test_fallback_xcode_configuration".format(name),

        # Inputs
        default_xcode_configuration = "custom",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": None,
                "run": None,
                "test": struct(
                    args = "inherit",
                    build_targets = [
                        "bt 1 label",
                        struct(
                            include = True,
                            label = "bt 4 label",
                            library_targets = [
                                struct(
                                    label = "lib label",
                                    post_actions = [],
                                    pre_actions = [],
                                ),
                            ],
                            post_actions = [],
                            pre_actions = [],
                            target_environment = "",
                        ),
                    ],
                    diagnostics = None,
                    env = "inherit",
                    env_include_defaults = "0",
                    options = None,
                    test_targets = [],
                    use_run_args_and_env = "1",
                    xcode_configuration = "",
                ),
            },
        ]),
        top_level_deps = top_level_deps,

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
                test = xcscheme_infos_testable.make_test(
                    build_targets = [
                        xcscheme_infos_testable.make_build_target("sim bt 1"),
                        xcscheme_infos_testable.make_build_target("sim bt 4"),
                        xcscheme_infos_testable.make_build_target(
                            "sim bt 4 lib",
                        ),
                    ],
                    test_targets = [],
                ),
            ),
        ],
    )

    _add_test(
        name = "{}_test_full".format(name),

        # Inputs
        default_xcode_configuration = "AppStore",
        json_str = json.encode([
            {
                "name": "A scheme",
                "profile": None,
                "run": None,
                "test": struct(
                    args = full_args,
                    build_targets = full_build_targets,
                    diagnostics = struct(
                        address_sanitizer = "1",
                        thread_sanitizer = "1",
                        undefined_behavior_sanitizer = "1",
                        main_thread_checker = "1",
                        thread_performance_checker = "1",
                    ),
                    env = full_env,
                    env_include_defaults = "1",
                    options = struct(
                        app_language = "en",
                        app_region = "US",
                        code_coverage = "0",
                    ),
                    test_targets = [
                        "tt 1 label",
                        struct(
                            enabled = "0",
                            label = "tt 2 label",
                            library_targets = [
                                struct(
                                    label = "lib label",
                                    post_actions = [
                                        xcscheme_infos_testable.make_pre_post_action(
                                            for_build = True,
                                            order = "144",
                                            script_text = "lib\nscript",
                                            title = "lib title",
                                        ),
                                    ],
                                    pre_actions = [
                                        xcscheme_infos_testable.make_pre_post_action(
                                            for_build = False,
                                            order = "",
                                            script_text = "lib script",
                                            title = "lib\ntitle",
                                        ),
                                    ],
                                ),
                            ],
                            post_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "7",
                                    script_text = "tt 2 script",
                                    title = "tt 2\nscript title",
                                ),
                            ],
                            pre_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "1",
                                    script_text = "tt\n2 script",
                                    title = "tt 2 script title",
                                ),
                            ],
                            target_environment = "device",
                        ),
                    ],
                    use_run_args_and_env = "0",
                    xcode_configuration = "custom",
                ),
            },
        ]),
        top_level_deps = top_level_deps,

        # Expected
        expected_infos = [
            xcscheme_infos_testable.make_scheme(
                name = "A scheme",
                test = xcscheme_infos_testable.make_test(
                    args = expected_full_args,
                    build_targets = [
                        xcscheme_infos_testable.make_build_target(
                            id = "device tt 2 lib",
                            post_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "144",
                                    script_text = "lib\nscript",
                                    title = "lib title",
                                ),
                            ],
                            pre_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "",
                                    script_text = "lib script",
                                    title = "lib\ntitle",
                                ),
                            ],
                        ),
                    ] + expected_full_build_targets,
                    diagnostics = xcscheme_infos_testable.make_diagnostics(
                        address_sanitizer = "1",
                        thread_sanitizer = "1",
                        undefined_behavior_sanitizer = "1",
                        main_thread_checker = "1",
                        thread_performance_checker = "1",
                    ),
                    env = expected_full_env,
                    env_include_defaults = "1",
                    options = xcscheme_infos_testable.make_test_options(
                        app_language = "en",
                        app_region = "US",
                        code_coverage = "0",
                    ),
                    test_targets = [
                        xcscheme_infos_testable.make_test_target("sim tt 1"),
                        xcscheme_infos_testable.make_test_target(
                            enabled = "0",
                            id = "device tt 2",
                            post_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "7",
                                    script_text = "tt 2 script",
                                    title = "tt 2\nscript title",
                                ),
                            ],
                            pre_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "1",
                                    script_text = "tt\n2 script",
                                    title = "tt 2 script title",
                                ),
                            ],
                        ),
                    ],
                    use_run_args_and_env = "0",
                    xcode_configuration = "custom",
                ),
            ),
        ],
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
