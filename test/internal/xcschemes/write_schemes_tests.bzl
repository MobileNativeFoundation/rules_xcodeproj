"""Tests for `xcschemes_execution.write_schemes`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")
load(":utils.bzl", "json_to_xcscheme_infos")

# buildifier: disable=bzl-visibility
# buildifier: disable=out-of-order-load
load(
    "//xcodeproj/internal/xcschemes:xcscheme_infos.bzl",
    "xcscheme_infos_testable",
)

# buildifier: disable=bzl-visibility
# buildifier: disable=out-of-order-load
load(
    "//xcodeproj/internal/xcschemes:xcschemes_execution.bzl",
    "xcschemes_execution",
)

# Utility

_CUSTOM_SCHEMES_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/custom_schemes_file",
)
_EXECUTION_ACTIONS_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/execution_actions_file",
)
_OUTPUT_DECLARED_DIRECTORY = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/xcschemes",
)
_TARGETS_ARGS_ENV_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/targets_args_env_file",
)
_XCSCHEMEMANAGEMENT_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/xcschememanagement.plist",
)

def _json_to_hosted_targets(json_str):
    return [
        _hosted_target(
            host = d["host"],
            hosted = d["hosted"],
        )
        for d in json.decode(json_str)
    ]

def _json_to_targets_env(json_str):
    return {
        id: [
            (k, v)
            for k, v in env
        ]
        for id, env in json.decode(json_str).items()
    }

def _hosted_target(*, host, hosted):
    return struct(
        host = host,
        hosted = hosted,
    )

# Test

def _write_schemes_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    actions = mock_actions.create()

    expected_declared_directories = {
        _OUTPUT_DECLARED_DIRECTORY: None,
    }
    expected_declared_files = {
        _CUSTOM_SCHEMES_DECLARED_FILE: None,
        _EXECUTION_ACTIONS_DECLARED_FILE: None,
        _TARGETS_ARGS_ENV_DECLARED_FILE: None,
        _XCSCHEMEMANAGEMENT_DECLARED_FILE: None,
    }
    expected_inputs = ctx.attr.consolidation_maps + [
        ctx.attr.autogeneration_config_file,
        _CUSTOM_SCHEMES_DECLARED_FILE,
        _EXECUTION_ACTIONS_DECLARED_FILE,
        ctx.attr.extension_point_identifiers_file,
        _TARGETS_ARGS_ENV_DECLARED_FILE,
    ]
    expected_outputs = [
        _OUTPUT_DECLARED_DIRECTORY,
        _XCSCHEMEMANAGEMENT_DECLARED_FILE,
    ]

    # Act

    (
        output_directory,
        xcschememanagement,
    ) = xcschemes_execution.write_schemes(
        actions = actions.mock,
        autogeneration_mode = ctx.attr.autogeneration_mode,
        autogeneration_config_file = ctx.attr.autogeneration_config_file,
        colorize = ctx.attr.colorize,
        consolidation_maps = ctx.attr.consolidation_maps,
        default_xcode_configuration = ctx.attr.default_xcode_configuration,
        extension_point_identifiers_file = (
            ctx.attr.extension_point_identifiers_file
        ),
        generator_name = "a_generator_name",
        hosted_targets = depset(
            _json_to_hosted_targets(ctx.attr.hosted_targets),
        ),
        install_path = ctx.attr.install_path,
        targets_args = ctx.attr.targets_args,
        targets_env = _json_to_targets_env(ctx.attr.targets_env),
        tool = None,
        workspace_directory = ctx.attr.workspace_directory,
        xcscheme_infos = json_to_xcscheme_infos(ctx.attr.xcscheme_infos),
    )

    # Assert

    asserts.equals(
        env,
        expected_declared_directories,
        actions.declared_directories,
        "actions.declare_directory",
    )

    asserts.equals(
        env,
        expected_declared_files,
        actions.declared_files,
        "actions.declare_file",
    )

    asserts.equals(
        env,
        ctx.attr.expected_writes,
        actions.writes,
        "actions.write",
    )

    asserts.equals(
        env,
        "@%s",
        actions.args_objects[0].captured.use_param_file_args["use_param_file"],
        "args[0].use_param_file",
    )

    asserts.equals(
        env,
        "multiline",
        actions.args_objects[0].captured.set_param_file_format_args["format"],
        "args[0].param_file_format",
    )

    asserts.equals(
        env,
        [actions.args_objects[0]],
        actions.run_args["arguments"],
        "actions.run.arguments",
    )

    asserts.equals(
        env,
        ctx.attr.expected_args,
        actions.args_objects[0].captured.args,
        "args[0] arguments",
    )

    asserts.equals(
        env,
        expected_inputs,
        actions.run_args["inputs"],
        "actions.run.inputs",
    )

    asserts.equals(
        env,
        expected_outputs,
        actions.run_args["outputs"],
        "actions.run.outputs",
    )

    asserts.equals(
        env,
        _OUTPUT_DECLARED_DIRECTORY,
        output_directory,
        "output_directory",
    )
    asserts.equals(
        env,
        _XCSCHEMEMANAGEMENT_DECLARED_FILE,
        xcschememanagement,
        "xcschememanagement",
    )

    return unittest.end(env)

write_schemes_test = unittest.make(
    impl = _write_schemes_test_impl,
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "autogeneration_mode": attr.string(mandatory = True),
        "autogeneration_config_file": attr.string(mandatory = True),
        "colorize": attr.bool(mandatory = True),
        "consolidation_maps": attr.string_list(mandatory = True),
        "default_xcode_configuration": attr.string(mandatory = True),
        "extension_point_identifiers_file": attr.string(mandatory = True),
        "hosted_targets": attr.string(mandatory = True),
        "install_path": attr.string(mandatory = True),
        "targets_args": attr.string_list_dict(mandatory = True),
        "targets_env": attr.string(mandatory = True),
        "workspace_directory": attr.string(mandatory = True),
        "xcscheme_infos": attr.string(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
        "expected_writes": attr.string_dict(mandatory = True),
    },
)

def write_schemes_test_suite(name):
    """Test suite for `xcschemes_execution.write_schemes`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,

            # Inputs
            autogeneration_mode,
            autogeneration_config_file,
            colorize = False,
            consolidation_maps,
            default_xcode_configuration,
            extension_point_identifiers_file,
            hosted_targets = [],
            install_path,
            targets_args = {},
            targets_env = {},
            workspace_directory,
            xcscheme_infos = [],

            # Expected
            expected_args,
            expected_writes):
        test_names.append(name)
        write_schemes_test(
            name = name,

            # Inputs
            autogeneration_mode = autogeneration_mode,
            autogeneration_config_file = autogeneration_config_file,
            colorize = colorize,
            consolidation_maps = consolidation_maps,
            default_xcode_configuration = default_xcode_configuration,
            extension_point_identifiers_file = extension_point_identifiers_file,
            hosted_targets = json.encode(hosted_targets),
            install_path = install_path,
            targets_args = targets_args,
            targets_env = json.encode(targets_env),
            workspace_directory = workspace_directory,
            xcscheme_infos = json.encode(xcscheme_infos),

            # Expected
            expected_args = expected_args,
            expected_writes = {
                file.path: content
                for file, content in expected_writes.items()
            },
        )

    no_custom_schemes_content = "\n".join([
        # schemeCount
        "0",
    ]) + "\n"

    no_target_args_and_env_content = "\n".join([
        # argsCount
        "0",
        # envCount
        "0",
    ]) + "\n"

    # Basic

    _add_test(
        name = "{}_basic".format(name),

        # Inputs
        autogeneration_mode = "none",
        autogeneration_config_file = "some/autogeneration-config-file",
        colorize = True,
        consolidation_maps = [
            "some/consolidation_maps/0",
            "some/consolidation_maps/1",
        ],
        default_xcode_configuration = "Debug",
        extension_point_identifiers_file = "a/extension_point_identifiers_file",
        install_path = "best/vision.xcodeproj",
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # outputDirectory
            _OUTPUT_DECLARED_DIRECTORY.path,
            # schemeManagementOutputPath
            _XCSCHEMEMANAGEMENT_DECLARED_FILE.path,
            # autogenerationMode
            "none",
            # autogenerationConfigFile
            "some/autogeneration-config-file",
            # defaultXcodeConfiguration
            "Debug",
            # workspace
            "/Users/TimApple/StarBoard",
            # installPath
            "best/vision.xcodeproj",
            # extensionPointIdentifiersFile
            "a/extension_point_identifiers_file",
            # executionActionsFile
            _EXECUTION_ACTIONS_DECLARED_FILE.path,
            # targetsArgsEnvFile
            _TARGETS_ARGS_ENV_DECLARED_FILE.path,
            # customSchemesFile
            _CUSTOM_SCHEMES_DECLARED_FILE.path,
            # consolidationMaps
            "--consolidation-maps",
            "some/consolidation_maps/0",
            "some/consolidation_maps/1",
            # colorize
            "--colorize",
        ],
        expected_writes = {
            _CUSTOM_SCHEMES_DECLARED_FILE: no_custom_schemes_content,
            _EXECUTION_ACTIONS_DECLARED_FILE: "\n",
            _TARGETS_ARGS_ENV_DECLARED_FILE: no_target_args_and_env_content,
        },
    )

    # Custom schemes

    _add_test(
        name = "{}_custom_schemes".format(name),

        # Inputs
        autogeneration_mode = "auto",
        autogeneration_config_file = "some/autogeneration-config-file",
        consolidation_maps = [
            "some/consolidation_maps/0",
            "some/consolidation_maps/1",
        ],
        default_xcode_configuration = "AppStore",
        extension_point_identifiers_file = "a/extension_point_identifiers_file",
        install_path = "best/vision.xcodeproj",
        workspace_directory = "/Users/TimApple/StarBoard",
        xcscheme_infos = [
            xcscheme_infos_testable.make_scheme(name = "Scheme 2"),
            xcscheme_infos_testable.make_scheme(
                name = "Scheme 1",
                profile = xcscheme_infos_testable.make_profile(
                    args = [
                        xcscheme_infos_testable.make_arg(
                            enabled = "1",
                            value = "simple value",
                        ),
                        xcscheme_infos_testable.make_arg(
                            enabled = "1",
                            literal_string = "0",
                            value = "simple value",
                        ),
                        xcscheme_infos_testable.make_arg(
                            enabled = "0",
                            value = "value\nwith\nnewlines",
                        ),
                    ],
                    build_targets = [
                        xcscheme_infos_testable.make_build_target(
                            id = "profile bt",
                            post_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "2",
                                    script_text = "profile bt post profile",
                                    title = "profile bt post profile title",
                                ),
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "3",
                                    script_text = "profile\nbt post build",
                                    title = "profile bt post build title",
                                ),
                            ],
                            pre_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "8",
                                    script_text = "profile bt pre profile",
                                    title = "profile bt pre profile title",
                                ),
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "4",
                                    script_text = "profile bt pre build",
                                    title = "profile bt\npre build title",
                                ),
                            ],
                        ),
                    ],
                    env = {
                        "B": xcscheme_infos_testable.make_env(
                            enabled = "1",
                            value = "a",
                        ),
                    },
                    env_include_defaults = "1",
                    launch_target = xcscheme_infos_testable.make_launch_target(
                        extension_host = "profile extension host id",
                        id = "profile launch id",
                        post_actions = [
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = False,
                                order = "",
                                script_text = "profile launch post profile",
                                title = "profile launch post profile title",
                            ),
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = True,
                                order = "2",
                                script_text = "profile\nlaunch post build",
                                title = "profile launch post build title",
                            ),
                        ],
                        pre_actions = [
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = False,
                                order = "1",
                                script_text = "profile launch pre profile",
                                title = "profile launch pre profile title",
                            ),
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = True,
                                order = "",
                                script_text = "profile launch pre build",
                                title = "profile launch\npre build title",
                            ),
                        ],
                        working_directory = "profile working dir",
                    ),
                    use_run_args_and_env = "0",
                    xcode_configuration = "Profile",
                ),
                run = xcscheme_infos_testable.make_run(
                    args = [
                        xcscheme_infos_testable.make_arg(
                            enabled = "0",
                            value = "a",
                        ),
                        xcscheme_infos_testable.make_arg(
                            enabled = "1",
                            value = "bb",
                        ),
                    ],
                    build_targets = [
                        xcscheme_infos_testable.make_build_target(
                            id = "run bt",
                            post_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "9",
                                    script_text = "run bt post run",
                                    title = "run bt post run title",
                                ),
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "11",
                                    script_text = "run\nbt post build",
                                    title = "run bt post build title",
                                ),
                            ],
                            pre_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "10",
                                    script_text = "run bt pre run",
                                    title = "run bt pre run title",
                                ),
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "100",
                                    script_text = "run bt pre build",
                                    title = "run bt\npre build title",
                                ),
                            ],
                        ),
                    ],
                    diagnostics = xcscheme_infos_testable.make_diagnostics(
                        address_sanitizer = "1",
                        thread_sanitizer = "1",
                        undefined_behavior_sanitizer = "1",
                        main_thread_checker = "1",
                        thread_performance_checker = "1",
                    ),
                    env = {
                        "A": xcscheme_infos_testable.make_env(
                            enabled = "0",
                            value = "value with spaces",
                        ),
                        "VAR WITH SPACES": xcscheme_infos_testable.make_env(
                            enabled = "1",
                            value = "value\nwith\nnewlines",
                        ),
                    },
                    env_include_defaults = "0",
                    launch_target = xcscheme_infos_testable.make_launch_target(
                        extension_host = "run extension host id",
                        id = "run launch id",
                        post_actions = [
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = False,
                                order = "",
                                script_text = "run launch post run",
                                title = "run launch post run title",
                            ),
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = True,
                                order = "2",
                                script_text = "run\nlaunch post build",
                                title = "run launch post build title",
                            ),
                        ],
                        pre_actions = [
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = False,
                                order = "1",
                                script_text = "run launch pre run",
                                title = "run launch pre run title",
                            ),
                            xcscheme_infos_testable.make_pre_post_action(
                                for_build = True,
                                order = "",
                                script_text = "run launch pre build",
                                title = "run launch\npre build title",
                            ),
                        ],
                        working_directory = "run working dir",
                    ),
                    xcode_configuration = "Run",
                ),
                test = xcscheme_infos_testable.make_test(
                    args = [
                        xcscheme_infos_testable.make_arg(
                            enabled = "0",
                            value = "-v",
                        ),
                    ],
                    build_targets = [
                        xcscheme_infos_testable.make_build_target(
                            id = "test bt 2",
                        ),
                        xcscheme_infos_testable.make_build_target(
                            id = "test bt 1",
                            post_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "",
                                    script_text = "test bt 1 post test",
                                    title = "test bt 1 post test title",
                                ),
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "2",
                                    script_text = "test bt 1 post build",
                                    title = "test bt 1 post build title",
                                ),
                            ],
                            pre_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "6",
                                    script_text = "test bt 1 pre test",
                                    title = "test bt 1 pre test title",
                                ),
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "7",
                                    script_text = "test bt 1 pre build",
                                    title = "test bt 1 pre build title",
                                ),
                            ],
                        ),
                    ],
                    diagnostics = xcscheme_infos_testable.make_diagnostics(
                        address_sanitizer = "1",
                        thread_sanitizer = "1",
                        undefined_behavior_sanitizer = "1",
                        main_thread_checker = "1",
                        thread_performance_checker = "1",
                    ),
                    env = {
                        "VAR\nWITH\nNEWLINES": xcscheme_infos_testable.make_env(
                            enabled = "0",
                            value = "simple",
                        ),
                    },
                    env_include_defaults = "1",
                    options = xcscheme_infos_testable.make_test_options(
                        app_language = "en",
                        app_region = "US",
                        code_coverage = "0",
                    ),
                    test_targets = [
                        xcscheme_infos_testable.make_test_target(
                            enabled = "0",
                            id = "test tt 1",
                            post_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "",
                                    script_text = "test tt 1 post\nbuild",
                                    title = "test tt 1 post build title",
                                ),
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "42",
                                    script_text = "test tt 1 post test",
                                    title = "test tt 1 post\ntest title",
                                ),
                            ],
                            pre_actions = [
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = False,
                                    order = "1",
                                    script_text = "test tt 1 pre test",
                                    title = "test tt 1 pre test title",
                                ),
                                xcscheme_infos_testable.make_pre_post_action(
                                    for_build = True,
                                    order = "",
                                    script_text = "test tt 1 pre build",
                                    title = "test tt 1 pre build title",
                                ),
                            ],
                        ),
                        xcscheme_infos_testable.make_test_target(
                            enabled = "1",
                            id = "test tt 2",
                        ),
                    ],
                    use_run_args_and_env = "0",
                    xcode_configuration = "Test",
                ),
            ),
            xcscheme_infos_testable.make_scheme(
                name = "Scheme 3",
                run = xcscheme_infos_testable.make_run(
                    launch_target = xcscheme_infos_testable.make_launch_target(
                        path = "/Foo/Bar.app",
                    ),
                ),
            ),
        ],

        # Expected
        expected_args = [
            # outputDirectory
            _OUTPUT_DECLARED_DIRECTORY.path,
            # schemeManagementOutputPath
            _XCSCHEMEMANAGEMENT_DECLARED_FILE.path,
            # autogenerationMode
            "auto",
            # autogenerationConfigFile
            "some/autogeneration-config-file",
            # defaultXcodeConfiguration
            "AppStore",
            # workspace
            "/Users/TimApple/StarBoard",
            # installPath
            "best/vision.xcodeproj",
            # extensionPointIdentifiersFile
            "a/extension_point_identifiers_file",
            # executionActionsFile
            _EXECUTION_ACTIONS_DECLARED_FILE.path,
            # targetsArgsEnvFile
            _TARGETS_ARGS_ENV_DECLARED_FILE.path,
            # customSchemesFile
            _CUSTOM_SCHEMES_DECLARED_FILE.path,
            # consolidationMaps
            "--consolidation-maps",
            "some/consolidation_maps/0",
            "some/consolidation_maps/1",
        ],
        expected_writes = {
            _EXECUTION_ACTIONS_DECLARED_FILE: "\n".join([
                # schemeName
                "Scheme 1",
                # action
                "test",
                # isPreAction
                "1",
                # title
                "test tt 1 pre test title",
                # scriptText
                "test tt 1 pre test",
                # id
                "test tt 1",
                # order
                "1",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "1",
                # title
                "test tt 1 pre build title",
                # scriptText
                "test tt 1 pre build",
                # id
                "test tt 1",
                # order
                "",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "0",
                # title
                "test tt 1 post build title",
                # scriptText
                "test tt 1 post\0build",
                # id
                "test tt 1",
                # order
                "",

                # schemeName
                "Scheme 1",
                # action
                "test",
                # isPreAction
                "0",
                # title
                "test tt 1 post\0test title",
                # scriptText
                "test tt 1 post test",
                # id
                "test tt 1",
                # order
                "42",

                # schemeName
                "Scheme 1",
                # action
                "test",
                # isPreAction
                "1",
                # title
                "test bt 1 pre test title",
                # scriptText
                "test bt 1 pre test",
                # id
                "test bt 1",
                # order
                "6",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "1",
                # title
                "test bt 1 pre build title",
                # scriptText
                "test bt 1 pre build",
                # id
                "test bt 1",
                # order
                "7",

                # schemeName
                "Scheme 1",
                # action
                "test",
                # isPreAction
                "0",
                # title
                "test bt 1 post test title",
                # scriptText
                "test bt 1 post test",
                # id
                "test bt 1",
                # order
                "",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "0",
                # title
                "test bt 1 post build title",
                # scriptText
                "test bt 1 post build",
                # id
                "test bt 1",
                # order
                "2",

                # schemeName
                "Scheme 1",
                # action
                "run",
                # isPreAction
                "1",
                # title
                "run bt pre run title",
                # scriptText
                "run bt pre run",
                # id
                "run bt",
                # order
                "10",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "1",
                # title
                "run bt\0pre build title",
                # scriptText
                "run bt pre build",
                # id
                "run bt",
                # order
                "100",

                # schemeName
                "Scheme 1",
                # action
                "run",
                # isPreAction
                "0",
                # title
                "run bt post run title",
                # scriptText
                "run bt post run",
                # id
                "run bt",
                # order
                "9",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "0",
                # title
                "run bt post build title",
                # scriptText
                "run\0bt post build",
                # id
                "run bt",
                # order
                "11",

                # schemeName
                "Scheme 1",
                # action
                "run",
                # isPreAction
                "1",
                # title
                "run launch pre run title",
                # scriptText
                "run launch pre run",
                # id
                "run launch id",
                # order
                "1",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "1",
                # title
                "run launch\0pre build title",
                # scriptText
                "run launch pre build",
                # id
                "run launch id",
                # order
                "",

                # schemeName
                "Scheme 1",
                # action
                "run",
                # isPreAction
                "0",
                # title
                "run launch post run title",
                # scriptText
                "run launch post run",
                # id
                "run launch id",
                # order
                "",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "0",
                # title
                "run launch post build title",
                # scriptText
                "run\0launch post build",
                # id
                "run launch id",
                # order
                "2",

                # schemeName
                "Scheme 1",
                # action
                "profile",
                # isPreAction
                "1",
                # title
                "profile bt pre profile title",
                # scriptText
                "profile bt pre profile",
                # id
                "profile bt",
                # order
                "8",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "1",
                # title
                "profile bt\0pre build title",
                # scriptText
                "profile bt pre build",
                # id
                "profile bt",
                # order
                "4",

                # schemeName
                "Scheme 1",
                # action
                "profile",
                # isPreAction
                "0",
                # title
                "profile bt post profile title",
                # scriptText
                "profile bt post profile",
                # id
                "profile bt",
                # order
                "2",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "0",
                # title
                "profile bt post build title",
                # scriptText
                "profile\0bt post build",
                # id
                "profile bt",
                # order
                "3",

                # schemeName
                "Scheme 1",
                # action
                "profile",
                # isPreAction
                "1",
                # title
                "profile launch pre profile title",
                # scriptText
                "profile launch pre profile",
                # id
                "profile launch id",
                # order
                "1",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "1",
                # title
                "profile launch\0pre build title",
                # scriptText
                "profile launch pre build",
                # id
                "profile launch id",
                # order
                "",

                # schemeName
                "Scheme 1",
                # action
                "profile",
                # isPreAction
                "0",
                # title
                "profile launch post profile title",
                # scriptText
                "profile launch post profile",
                # id
                "profile launch id",
                # order
                "",

                # schemeName
                "Scheme 1",
                # action
                "build",
                # isPreAction
                "0",
                # title
                "profile launch post build title",
                # scriptText
                "profile\0launch post build",
                # id
                "profile launch id",
                # order
                "2",
            ]) + "\n",
            _TARGETS_ARGS_ENV_DECLARED_FILE: no_target_args_and_env_content,
            _CUSTOM_SCHEMES_DECLARED_FILE: "\n".join([
                # schemeCount
                "3",
                # - name
                "Scheme 2",
                # - test - testTargetCount
                "0",
                # - test - buildTargets
                "",
                # - test - commandLineArguments count
                "-1",
                # - test - environmentVariables count
                "-1",
                # - test - environmentVariablesIncludeDefaults
                "0",
                # - test - useRunArgsAndEnv
                "1",
                # - test - enableAddressSanitizer
                "0",
                # - test - enableThreadSanitizer
                "0",
                # - test - enableUBSanitizer
                "0",
                # - test - enableMainThreadChecker
                "1",
                # - test - enableThreadPerformanceChecker
                "1",
                # - test - app_language
                "",
                # - test - app_region
                "",
                # - test - code_coverage
                "0",
                # - test - xcodeConfiguration
                "",
                # - run - buildTargets
                "",
                # - run - commandLineArguments count
                "-1",
                # - run - environmentVariables count
                "-1",
                # - run - environmentVariablesIncludeDefaults
                "1",
                # - run - enableAddressSanitizer
                "0",
                # - run - enableThreadSanitizer
                "0",
                # - run - enableUBSanitizer
                "0",
                # - test - enableMainThreadChecker
                "1",
                # - test - enableThreadPerformanceChecker
                "1",
                # - run - xcodeConfiguration
                "",
                # - run - launchTarget - isPath
                "0",
                # - run - launchTarget - id
                "",
                # - run - launchTarget - extensionHostID
                "",
                # - run - customWorkingDirectory
                "",
                # - profile - buildTargets
                "",
                # - profile - commandLineArguments count
                "-1",
                # - profile - environmentVariables count
                "-1",
                # - profile - environmentVariablesIncludeDefaults
                "0",
                # - profile - useRunArgsAndEnv
                "1",
                # - profile - xcodeConfiguration
                "",
                # - profile - launchTarget - isPath
                "0",
                # - profile - launchTarget - id
                "",
                # - profile - launchTarget - extensionHostID
                "",
                # - profile - customWorkingDirectory
                "",

                # - name
                "Scheme 1",
                # - test - testTargetCount
                "2",
                # - test - testTargets - id
                "test tt 1",
                # - test - testTargets - enabled
                "0",
                # - test - testTargets - id
                "test tt 2",
                # - test - testTargets - enabled
                "1",
                # - test - buildTargets
                "test bt 2",
                "test bt 1",
                "",
                # - test - commandLineArguments count
                "1",
                # - test - commandLineArguments - value
                "-v",
                # - test - commandLineArguments - enabled
                "0",
                # - test - commandLineArguments - literalString
                "1",
                # - test - environmentVariables count
                "1",
                # - test - environmentVariables - key
                "VAR\0WITH\0NEWLINES",
                # - test - environmentVariables - value
                "simple",
                # - test - environmentVariables - enabled
                "0",
                # - test - environmentVariablesIncludeDefaults
                "1",
                # - test - useRunArgsAndEnv
                "0",
                # - test - enableAddressSanitizer
                "1",
                # - test - enableThreadSanitizer
                "1",
                # - test - enableUBSanitizer
                "1",
                # - test - enableMainThreadChecker
                "1",
                # - test - enableThreadPerformanceChecker
                "1",
                # - test - app_language
                "en",
                # - test - app_region
                "US",
                # - test - code_coverage
                "0",
                # - test - xcodeConfiguration
                "Test",
                # - run - buildTargets
                "run bt",
                "",
                # - run - commandLineArguments count
                "2",
                # - run - commandLineArguments - value
                "a",
                # - run - commandLineArguments - enabled
                "0",
                # - run - commandLineArguments - literalString
                "1",
                # - run - commandLineArguments - value
                "bb",
                # - run - commandLineArguments - enabled
                "1",
                # - run - commandLineArguments - literalString
                "1",
                # - run - environmentVariables count
                "2",
                # - run - environmentVariables - key
                "A",
                # - run - environmentVariables - value
                "value with spaces",
                # - run - environmentVariables - enabled
                "0",
                # - run - environmentVariables - key
                "VAR WITH SPACES",
                # - run - environmentVariables - value
                "value\0with\0newlines",
                # - run - environmentVariables - enabled
                "1",
                # - run - environmentVariablesIncludeDefaults
                "0",
                # - run - enableAddressSanitizer
                "1",
                # - run - enableThreadSanitizer
                "1",
                # - run - enableUBSanitizer
                "1",
                # - test - enableMainThreadChecker
                "1",
                # - test - enableThreadPerformanceChecker
                "1",
                # - run - xcodeConfiguration
                "Run",
                # - run - launchTarget - isPath
                "0",
                # - run - launchTarget - id
                "run launch id",
                # - run - launchTarget - extensionHostID
                "run extension host id",
                # - run - customWorkingDirectory
                "run working dir",
                # - profile - buildTargets
                "profile bt",
                "",
                # - profile - commandLineArguments count
                "3",
                # - profile - commandLineArguments - value
                "simple value",
                # - profile - commandLineArguments - enabled
                "1",
                # - profile - commandLineArguments - literalString
                "1",
                # - profile - commandLineArguments - value
                "simple value",
                # - profile - commandLineArguments - enabled
                "1",
                # - profile - commandLineArguments - literalString
                "0",
                # - profile - commandLineArguments - value
                "value\0with\0newlines",
                # - profile - commandLineArguments - enabled
                "0",
                # - profile - commandLineArguments - literalString
                "1",
                # - profile - environmentVariables count
                "1",
                # - profile - environmentVariables - key
                "B",
                # - profile - environmentVariables - value
                "a",
                # - profile - environmentVariables - enabled
                "1",
                # - profile - environmentVariablesIncludeDefaults
                "1",
                # - profile - useRunArgsAndEnv
                "0",
                # - profile - xcodeConfiguration
                "Profile",
                # - profile - launchTarget - isPath
                "0",
                # - profile - launchTarget - id
                "profile launch id",
                # - profile - launchTarget - extensionHostID
                "profile extension host id",
                # - profile - customWorkingDirectory
                "profile working dir",

                # - name
                "Scheme 3",
                # - test - testTargetCount
                "0",
                # - test - buildTargets
                "",
                # - test - commandLineArguments count
                "-1",
                # - test - environmentVariables count
                "-1",
                # - test - environmentVariablesIncludeDefaults
                "0",
                # - test - useRunArgsAndEnv
                "1",
                # - test - enableAddressSanitizer
                "0",
                # - test - enableThreadSanitizer
                "0",
                # - test - enableUBSanitizer
                "0",
                # - test - enableMainThreadChecker
                "1",
                # - test - enableThreadPerformanceChecker
                "1",
                # - test - app_language
                "",
                # - test - app_region
                "",
                # - test - code_coverage
                "0",
                # - test - xcodeConfiguration
                "",
                # - run - buildTargets
                "",
                # - run - commandLineArguments count
                "-1",
                # - run - environmentVariables count
                "-1",
                # - run - environmentVariablesIncludeDefaults
                "1",
                # - run - enableAddressSanitizer
                "0",
                # - run - enableThreadSanitizer
                "0",
                # - run - enableUBSanitizer
                "0",
                # - test - enableMainThreadChecker
                "1",
                # - test - enableThreadPerformanceChecker
                "1",
                # - run - xcodeConfiguration
                "",
                # - run - launchTarget - isPath
                "1",
                # - run - launchTarget - path
                "/Foo/Bar.app",
                # - run - customWorkingDirectory
                "",
                # - profile - buildTargets
                "",
                # - profile - commandLineArguments count
                "-1",
                # - profile - environmentVariables count
                "-1",
                # - profile - environmentVariablesIncludeDefaults
                "0",
                # - profile - useRunArgsAndEnv
                "1",
                # - profile - xcodeConfiguration
                "",
                # - profile - launchTarget - isPath
                "0",
                # - profile - launchTarget - id
                "",
                # - profile - launchTarget - extensionHostID
                "",
                # - profile - customWorkingDirectory
                "",
            ]) + "\n",
        },
    )

    # hosted_targets

    _add_test(
        name = "{}_hosted_targets".format(name),

        # Inputs
        autogeneration_mode = "auto",
        autogeneration_config_file = "some/autogeneration-config-file",
        consolidation_maps = [
            "some/consolidation_maps/0",
            "some/consolidation_maps/1",
        ],
        default_xcode_configuration = "AppStore",
        extension_point_identifiers_file = "a/extension_point_identifiers_file",
        hosted_targets = [
            _hosted_target(
                host = "IOS_APP_2",
                hosted = "IOS_APP_EXTENSION_1",
            ),
            _hosted_target(
                host = "IOS_APP_1",
                hosted = "IOS_APP_EXTENSION_1",
            ),
            _hosted_target(
                host = "IOS_APP_2",
                hosted = "IOS_APP_EXTENSION_2",
            ),
        ],
        install_path = "best/vision.xcodeproj",
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # outputDirectory
            _OUTPUT_DECLARED_DIRECTORY.path,
            # schemeManagementOutputPath
            _XCSCHEMEMANAGEMENT_DECLARED_FILE.path,
            # autogenerationMode
            "auto",
            # autogenerationConfigFile
            "some/autogeneration-config-file",
            # defaultXcodeConfiguration
            "AppStore",
            # workspace
            "/Users/TimApple/StarBoard",
            # installPath
            "best/vision.xcodeproj",
            # extensionPointIdentifiersFile
            "a/extension_point_identifiers_file",
            # executionActionsFile
            _EXECUTION_ACTIONS_DECLARED_FILE.path,
            # targetsArgsEnvFile
            _TARGETS_ARGS_ENV_DECLARED_FILE.path,
            # customSchemesFile
            _CUSTOM_SCHEMES_DECLARED_FILE.path,
            # consolidationMaps
            "--consolidation-maps",
            "some/consolidation_maps/0",
            "some/consolidation_maps/1",
            # targetAndExtensionHosts
            "--target-and-extension-hosts",
            "IOS_APP_EXTENSION_1",
            "IOS_APP_2",
            "IOS_APP_EXTENSION_1",
            "IOS_APP_1",
            "IOS_APP_EXTENSION_2",
            "IOS_APP_2",
        ],
        expected_writes = {
            _CUSTOM_SCHEMES_DECLARED_FILE: no_custom_schemes_content,
            _EXECUTION_ACTIONS_DECLARED_FILE: "\n",
            _TARGETS_ARGS_ENV_DECLARED_FILE: no_target_args_and_env_content,
        },
    )

    # Target args and env

    _add_test(
        name = "{}_target_args_and_env".format(name),

        # Inputs
        autogeneration_mode = "auto",
        autogeneration_config_file = "some/autogeneration-config-file",
        consolidation_maps = [
            "some/consolidation_maps/0",
            "some/consolidation_maps/1",
        ],
        default_xcode_configuration = "AppStore",
        extension_point_identifiers_file = "a/extension_point_identifiers_file",
        install_path = "best/vision.xcodeproj",
        targets_args = {
            "IOS_APP": [
                "--ios_app_arg_0",
                "--ios_app_arg with spaces",
            ],
            "MACOS_APP": [
                "--macos_app_arg\nwith\nnewlines",
            ],
        },
        targets_env = {
            "IOS_TEST": [
                ("VAR1", "VALUE WITH SPACES"),
                ("VAR WITH SPACES", "value\nwith\nnewlines"),
                ("VAR\nWITH\nNEWLINES", "simple_value"),
            ],
        },
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # outputDirectory
            _OUTPUT_DECLARED_DIRECTORY.path,
            # schemeManagementOutputPath
            _XCSCHEMEMANAGEMENT_DECLARED_FILE.path,
            # autogenerationMode
            "auto",
            # autogenerationConfigFile
            "some/autogeneration-config-file",
            # defaultXcodeConfiguration
            "AppStore",
            # workspace
            "/Users/TimApple/StarBoard",
            # installPath
            "best/vision.xcodeproj",
            # extensionPointIdentifiersFile
            "a/extension_point_identifiers_file",
            # executionActionsFile
            _EXECUTION_ACTIONS_DECLARED_FILE.path,
            # targetsArgsEnvFile
            _TARGETS_ARGS_ENV_DECLARED_FILE.path,
            # customSchemesFile
            _CUSTOM_SCHEMES_DECLARED_FILE.path,
            # consolidationMaps
            "--consolidation-maps",
            "some/consolidation_maps/0",
            "some/consolidation_maps/1",
        ],
        expected_writes = {
            _CUSTOM_SCHEMES_DECLARED_FILE: no_custom_schemes_content,
            _EXECUTION_ACTIONS_DECLARED_FILE: "\n",
            _TARGETS_ARGS_ENV_DECLARED_FILE: "\n".join([
                # argsCount
                "2",
                # - id
                "IOS_APP",
                # - targetArgsCount
                "2",
                # - - values
                "--ios_app_arg_0",
                "--ios_app_arg with spaces",
                # - id
                "MACOS_APP",
                # - targetArgsCount
                "1",
                # - - values
                "--macos_app_arg\0with\0newlines",
                # envCount
                "1",
                # - id
                "IOS_TEST",
                # - targetEnvCount
                "3",
                # - - key
                "VAR1",
                # - - value
                "VALUE WITH SPACES",
                # - - key
                "VAR WITH SPACES",
                # - - value
                "value\0with\0newlines",
                # - - key
                "VAR\0WITH\0NEWLINES",
                # - - value
                "simple_value",
            ]) + "\n",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
