"""Tests for the `xcschemes_infos_testable` module."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal/xcschemes:xcscheme_infos.bzl",
    "xcscheme_infos_testable",
)

def _info_constructors_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange / Act

    expected_info = json.decode(ctx.attr.expected_info)
    info = json.decode(ctx.attr.info)

    # Assert

    asserts.equals(
        env,
        expected_info,
        info,
    )

    return unittest.end(env)

info_constructors_test = unittest.make(
    impl = _info_constructors_test_impl,
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "info": attr.string(mandatory = True),

        # Expected
        "expected_info": attr.string(mandatory = True),
    },
)

def info_constructors_test_suite(name):
    """Test suite for `xcscheme_infos` constructors (i.e. \
    `xcscheme_infos_testable`).

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,

            # Inputs
            info,

            # Expected
            expected_info):
        test_names.append(name)
        info_constructors_test(
            name = name,

            # Inputs
            info = json.encode(info),

            # Expected
            expected_info = json.encode(expected_info),
        )

    # make_arg

    _add_test(
        name = "{}_make_arg_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_arg(value = "a\nnew line"),

        # Expected
        expected_info = struct(
            enabled = "1",
            literal_string = "1",
            value = "a\nnew line",
        ),
    )

    _add_test(
        name = "{}_make_arg_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_arg(
            enabled = "0",
            literal_string = "0",
            value = "b",
        ),

        # Expected
        expected_info = struct(
            enabled = "0",
            literal_string = "0",
            value = "b",
        ),
    )

    # make_env

    _add_test(
        name = "{}_make_env_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_env(value = "a\nnew line"),

        # Expected
        expected_info = struct(
            enabled = "1",
            value = "a\nnew line",
        ),
    )

    _add_test(
        name = "{}_make_env_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_env(
            enabled = "0",
            value = "b",
        ),

        # Expected
        expected_info = struct(
            enabled = "0",
            value = "b",
        ),
    )

    # make_build_target

    _add_test(
        name = "{}_make_build_target_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_build_target(id = "an id"),

        # Expected
        expected_info = struct(
            id = "an id",
            post_actions = [],
            pre_actions = [],
        ),
    )

    _add_test(
        name = "{}_make_build_target_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_build_target(
            id = "different id",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "script",
                    title = "title",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "1",
                    script_text = "s",
                    title = "t",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "ss",
                    title = "tt",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "11",
                    script_text = "sss",
                    title = "ttt",
                ),
            ],
        ),

        # Expected
        expected_info = struct(
            id = "different id",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "script",
                    title = "title",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "1",
                    script_text = "s",
                    title = "t",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "ss",
                    title = "tt",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "11",
                    script_text = "sss",
                    title = "ttt",
                ),
            ],
        ),
    )

    # make_diagnostics

    _add_test(
        name = "{}_make_diagnostics_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_diagnostics(),

        # Expected
        expected_info = struct(
            address_sanitizer = "0",
            thread_sanitizer = "0",
            undefined_behavior_sanitizer = "0",
            main_thread_checker = "1",
            thread_performance_checker = "1",
        ),
    )

    _add_test(
        name = "{}_make_diagnostics_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_diagnostics(
            address_sanitizer = "1",
            thread_sanitizer = "1",
            undefined_behavior_sanitizer = "1",
            main_thread_checker = "1",
            thread_performance_checker = "1",
        ),

        # Expected
        expected_info = struct(
            address_sanitizer = "1",
            thread_sanitizer = "1",
            undefined_behavior_sanitizer = "1",
            main_thread_checker = "1",
            thread_performance_checker = "1",
        ),
    )

    # make_test_options

    _add_test(
        name = "{}_make_test_options_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_test_options(),

        # Expected
        expected_info = struct(
            app_language = "",
            app_region = "",
            code_coverage = "0",
        ),
    )

    _add_test(
        name = "{}_make_test_options_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_test_options(
            app_language = "en",
            app_region = "US",
            code_coverage = "0",
        ),

        # Expected
        expected_info = struct(
            app_language = "en",
            app_region = "US",
            code_coverage = "0",
        ),
    )

    # make_launch_target

    _add_test(
        name = "{}_make_launch_target_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_launch_target(),

        # Expected
        expected_info = struct(
            extension_host = "",
            id = "",
            is_path = "0",
            post_actions = [],
            pre_actions = [],
            working_directory = "",
        ),
    )

    _add_test(
        name = "{}_make_launch_target_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_launch_target(
            extension_host = "host id",
            id = "an id",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "script",
                    title = "title",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "1",
                    script_text = "s",
                    title = "t",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "ss",
                    title = "tt",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "11",
                    script_text = "sss",
                    title = "ttt",
                ),
            ],
            working_directory = "a working directory",
        ),

        # Expected
        expected_info = struct(
            extension_host = "host id",
            id = "an id",
            is_path = "0",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "script",
                    title = "title",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "1",
                    script_text = "s",
                    title = "t",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "ss",
                    title = "tt",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "11",
                    script_text = "sss",
                    title = "ttt",
                ),
            ],
            working_directory = "a working directory",
        ),
    )

    _add_test(
        name = "{}_make_launch_target_is_path_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_launch_target(
            path = "/Foo/Bar.app",
        ),

        # Expected
        expected_info = struct(
            is_path = "1",
            path = "/Foo/Bar.app",
            post_actions = [],
            pre_actions = [],
            working_directory = "",
        ),
    )

    _add_test(
        name = "{}_make_launch_target_is_path_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_launch_target(
            path = "/Foo/Bar.app",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "script",
                    title = "title",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "1",
                    script_text = "s",
                    title = "t",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "ss",
                    title = "tt",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "11",
                    script_text = "sss",
                    title = "ttt",
                ),
            ],
            working_directory = "/Foo",
        ),

        # Expected
        expected_info = struct(
            is_path = "1",
            path = "/Foo/Bar.app",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "script",
                    title = "title",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "1",
                    script_text = "s",
                    title = "t",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "ss",
                    title = "tt",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "11",
                    script_text = "sss",
                    title = "ttt",
                ),
            ],
            working_directory = "/Foo",
        ),
    )

    # make_pre_post_action

    _add_test(
        name = "{}_make_pre_post_action".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_pre_post_action(
            for_build = True,
            order = "2",
            script_text = "script\ntext",
            title = "title\ntext",
        ),

        # Expected
        expected_info = struct(
            for_build = True,
            order = "2",
            script_text = "script\ntext",
            title = "title\ntext",
        ),
    )

    # make_profile

    _add_test(
        name = "{}_make_profile_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_profile(),

        # Expected
        expected_info = struct(
            args = None,
            build_targets = [],
            env = None,
            env_include_defaults = "0",
            launch_target = xcscheme_infos_testable.make_launch_target(),
            use_run_args_and_env = "1",
            xcode_configuration = "",
        ),
    )

    _add_test(
        name = "{}_make_profile_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_profile(
            args = [
                xcscheme_infos_testable.make_arg(
                    enabled = "1",
                    value = "a\nnew line",
                ),
                xcscheme_infos_testable.make_arg(
                    enabled = "0",
                    value = "b",
                ),
            ],
            build_targets = [
                xcscheme_infos_testable.make_build_target("bt 2"),
                xcscheme_infos_testable.make_build_target("bt 0"),
            ],
            env = {
                "VAR\n0": xcscheme_infos_testable.make_env("value 0"),
                "VAR 1": xcscheme_infos_testable.make_env("value\n1"),
            },
            env_include_defaults = "1",
            launch_target = xcscheme_infos_testable.make_launch_target("L"),
            use_run_args_and_env = "0",
            xcode_configuration = "Profile",
        ),

        # Expected
        expected_info = struct(
            args = [
                xcscheme_infos_testable.make_arg(
                    enabled = "1",
                    value = "a\nnew line",
                ),
                xcscheme_infos_testable.make_arg(
                    enabled = "0",
                    value = "b",
                ),
            ],
            build_targets = [
                xcscheme_infos_testable.make_build_target("bt 2"),
                xcscheme_infos_testable.make_build_target("bt 0"),
            ],
            env = {
                "VAR\n0": xcscheme_infos_testable.make_env("value 0"),
                "VAR 1": xcscheme_infos_testable.make_env("value\n1"),
            },
            env_include_defaults = "1",
            launch_target = xcscheme_infos_testable.make_launch_target("L"),
            use_run_args_and_env = "0",
            xcode_configuration = "Profile",
        ),
    )

    # make_run

    _add_test(
        name = "{}_make_run_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_run(),

        # Expected
        expected_info = struct(
            args = None,
            build_targets = [],
            diagnostics = xcscheme_infos_testable.make_diagnostics(),
            env = None,
            env_include_defaults = "1",
            launch_target = xcscheme_infos_testable.make_launch_target(),
            xcode_configuration = "",
        ),
    )

    _add_test(
        name = "{}_make_run_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_run(
            args = [
                xcscheme_infos_testable.make_arg(
                    enabled = "1",
                    value = "a\nnew line",
                ),
                xcscheme_infos_testable.make_arg(
                    enabled = "0",
                    value = "b",
                ),
            ],
            build_targets = [
                xcscheme_infos_testable.make_build_target("bt 2"),
                xcscheme_infos_testable.make_build_target("bt 0"),
            ],
            diagnostics = xcscheme_infos_testable.make_diagnostics(
                undefined_behavior_sanitizer = "1",
            ),
            env = {
                "VAR\n0": xcscheme_infos_testable.make_env("value 0"),
                "VAR 1": xcscheme_infos_testable.make_env("value\n1"),
            },
            env_include_defaults = "0",
            launch_target = xcscheme_infos_testable.make_launch_target("L"),
            xcode_configuration = "Run",
        ),

        # Expected
        expected_info = struct(
            args = [
                xcscheme_infos_testable.make_arg(
                    enabled = "1",
                    value = "a\nnew line",
                ),
                xcscheme_infos_testable.make_arg(
                    enabled = "0",
                    value = "b",
                ),
            ],
            build_targets = [
                xcscheme_infos_testable.make_build_target("bt 2"),
                xcscheme_infos_testable.make_build_target("bt 0"),
            ],
            diagnostics = xcscheme_infos_testable.make_diagnostics(
                undefined_behavior_sanitizer = "1",
            ),
            env = {
                "VAR\n0": xcscheme_infos_testable.make_env("value 0"),
                "VAR 1": xcscheme_infos_testable.make_env("value\n1"),
            },
            env_include_defaults = "0",
            launch_target = xcscheme_infos_testable.make_launch_target(
                id = "L",
            ),
            xcode_configuration = "Run",
        ),
    )

    # make_scheme

    _add_test(
        name = "{}_make_scheme_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_scheme(name = "a Scheme"),

        # Expected
        expected_info = struct(
            name = "a Scheme",
            profile = xcscheme_infos_testable.make_profile(),
            run = xcscheme_infos_testable.make_run(),
            test = xcscheme_infos_testable.make_test(),
        ),
    )

    _add_test(
        name = "{}_make_scheme_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_scheme(
            name = "scheme",
            profile = xcscheme_infos_testable.make_profile(
                xcode_configuration = "P",
            ),
            run = xcscheme_infos_testable.make_run(
                xcode_configuration = "R",
            ),
            test = xcscheme_infos_testable.make_test(
                xcode_configuration = "R",
            ),
        ),

        # Expected
        expected_info = struct(
            name = "scheme",
            profile = xcscheme_infos_testable.make_profile(
                xcode_configuration = "P",
            ),
            run = xcscheme_infos_testable.make_run(
                xcode_configuration = "R",
            ),
            test = xcscheme_infos_testable.make_test(
                xcode_configuration = "R",
            ),
        ),
    )

    # make_test

    _add_test(
        name = "{}_make_test_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_test(),

        # Expected
        expected_info = struct(
            args = None,
            build_targets = [],
            diagnostics = xcscheme_infos_testable.make_diagnostics(),
            env = None,
            env_include_defaults = "0",
            options = xcscheme_infos_testable.make_test_options(),
            test_targets = [],
            use_run_args_and_env = "1",
            xcode_configuration = "",
        ),
    )

    _add_test(
        name = "{}_make_test_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_test(
            args = [
                xcscheme_infos_testable.make_arg(
                    enabled = "1",
                    value = "a\nnew line",
                ),
                xcscheme_infos_testable.make_arg(
                    enabled = "0",
                    value = "b",
                ),
            ],
            build_targets = [
                xcscheme_infos_testable.make_build_target("bt 2"),
                xcscheme_infos_testable.make_build_target("bt 0"),
            ],
            diagnostics = xcscheme_infos_testable.make_diagnostics(
                thread_sanitizer = "1",
            ),
            env = {
                "VAR\n0": xcscheme_infos_testable.make_env("value 0"),
                "VAR 1": xcscheme_infos_testable.make_env("value\n1"),
            },
            env_include_defaults = "1",
            options = xcscheme_infos_testable.make_test_options(
                app_language = "en",
                app_region = "US",
                code_coverage = "0",
            ),
            test_targets = [
                xcscheme_infos_testable.make_test_target("tt 9"),
                xcscheme_infos_testable.make_test_target("tt 0"),
                xcscheme_infos_testable.make_test_target("tt 1"),
            ],
            use_run_args_and_env = "0",
            xcode_configuration = "Test",
        ),

        # Expected
        expected_info = struct(
            args = [
                xcscheme_infos_testable.make_arg(
                    enabled = "1",
                    value = "a\nnew line",
                ),
                xcscheme_infos_testable.make_arg(
                    enabled = "0",
                    value = "b",
                ),
            ],
            build_targets = [
                xcscheme_infos_testable.make_build_target("bt 2"),
                xcscheme_infos_testable.make_build_target("bt 0"),
            ],
            diagnostics = xcscheme_infos_testable.make_diagnostics(
                thread_sanitizer = "1",
            ),
            env = {
                "VAR\n0": xcscheme_infos_testable.make_env("value 0"),
                "VAR 1": xcscheme_infos_testable.make_env("value\n1"),
            },
            env_include_defaults = "1",
            options = xcscheme_infos_testable.make_test_options(
                app_language = "en",
                app_region = "US",
                code_coverage = "0",
            ),
            test_targets = [
                xcscheme_infos_testable.make_test_target("tt 9"),
                xcscheme_infos_testable.make_test_target("tt 0"),
                xcscheme_infos_testable.make_test_target("tt 1"),
            ],
            use_run_args_and_env = "0",
            xcode_configuration = "Test",
        ),
    )

    # make_test_target

    _add_test(
        name = "{}_make_test_target_minimal".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_test_target("an id"),

        # Expected
        expected_info = struct(
            enabled = "1",
            id = "an id",
            post_actions = [],
            pre_actions = [],
        ),
    )

    _add_test(
        name = "{}_make_test_target_full".format(name),

        # Inputs
        info = xcscheme_infos_testable.make_test_target(
            enabled = "0",
            id = "different id",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "script",
                    title = "title",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "1",
                    script_text = "s",
                    title = "t",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "ss",
                    title = "tt",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "11",
                    script_text = "sss",
                    title = "ttt",
                ),
            ],
        ),

        # Expected
        expected_info = struct(
            enabled = "0",
            id = "different id",
            post_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "",
                    script_text = "script",
                    title = "title",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "1",
                    script_text = "s",
                    title = "t",
                ),
            ],
            pre_actions = [
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = True,
                    order = "2",
                    script_text = "ss",
                    title = "tt",
                ),
                xcscheme_infos_testable.make_pre_post_action(
                    for_build = False,
                    order = "11",
                    script_text = "sss",
                    title = "ttt",
                ),
            ],
        ),
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
