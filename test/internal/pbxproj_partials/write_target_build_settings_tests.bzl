"""Tests for `pbxproj_partials.write_target_build_settings`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_BUILD_SETTINGS_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name.rules_xcodeproj.build_settings",
)
_DEBUG_SETTINGS_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name.rules_xcodeproj.debug_settings",
)
_C_PARAMS_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name.c.compile.params",
)
_CXX_PARAMS_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name.c.compile.params",
)

def _write_target_build_settings_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    actions = mock_actions.create()

    expected_declared_files = {}
    expected_inputs = []
    expected_outputs = []
    expected_params = []

    if ctx.attr.expect_build_settings:
        expected_build_settings = _BUILD_SETTINGS_DECLARED_FILE
        expected_declared_files[expected_build_settings] = None
        expected_outputs.append(expected_build_settings)
    else:
        expected_build_settings = None

    if ctx.attr.expect_debug_settings:
        expected_debug_settings = _DEBUG_SETTINGS_DECLARED_FILE
        expected_declared_files[expected_debug_settings] = None
        expected_outputs.append(expected_debug_settings)
    else:
        expected_debug_settings = None

    if ctx.attr.expect_c_params:
        expected_declared_files[_C_PARAMS_DECLARED_FILE] = None
        expected_outputs.append(_C_PARAMS_DECLARED_FILE)
        expected_params.append(_C_PARAMS_DECLARED_FILE)
    if ctx.attr.expect_cxx_params:
        expected_declared_files[_CXX_PARAMS_DECLARED_FILE] = None
        expected_outputs.append(_CXX_PARAMS_DECLARED_FILE)
        expected_params.append(_CXX_PARAMS_DECLARED_FILE)

    # Act

    (
        build_settings,
        debug_settings,
        params,
    ) = pbxproj_partials.write_target_build_settings(
        actions = actions.mock,
        apple_generate_dsym = ctx.attr.apple_generate_dsym,
        certificate_name = ctx.attr.certificate_name,
        colorize = ctx.attr.colorize,
        name = "a_target_name",
        tool = None,
    )

    # Assert

    asserts.equals(
        env,
        expected_declared_files,
        actions.declared_files,
        "actions.declare_file",
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
        expected_build_settings,
        build_settings,
        "build_settings",
    )
    asserts.equals(
        env,
        expected_debug_settings,
        debug_settings,
        "debug_settings",
    )
    asserts.equals(
        env,
        expected_params,
        params,
        "params",
    )

    return unittest.end(env)

write_target_build_settings_test = unittest.make(
    impl = _write_target_build_settings_test_impl,
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "apple_generate_dsym": attr.bool(mandatory = True),
        "certificate_name": attr.string(mandatory = True),
        "colorize": attr.bool(mandatory = True),

        # Expected
        "expect_build_settings": attr.bool(mandatory = True),
        "expect_c_params": attr.bool(mandatory = True),
        "expect_cxx_params": attr.bool(mandatory = True),
        "expect_debug_settings": attr.bool(mandatory = True),
        "expected_args": attr.string_list(mandatory = True),
    },
)

def write_target_build_settings_test_suite(name):
    """Test suite for `pbxproj_partials.write_target_build_settings`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,

            # Inputs
            buildfile_subidentifiers_files,
            colorize = False,
            compile_stub_needed = False,
            execution_root_file,
            files = [],
            file_paths = [],
            folders = [],
            install_path,
            project_options,
            selected_model_versions_file,
            workspace_directory,

            # Expected
            expected_args,
            expected_writes):
        test_names.append(name)
        write_target_build_settings_test(
            name = name,

            # Inputs
            buildfile_subidentifiers_files = buildfile_subidentifiers_files,
            colorize = colorize,
            compile_stub_needed = compile_stub_needed,
            execution_root_file = execution_root_file,
            files = files,
            file_paths = file_paths,
            folders = folders,
            install_path = install_path,
            project_options = project_options,
            selected_model_versions_file = selected_model_versions_file,
            workspace_directory = workspace_directory,

            # Expected
            expected_args = expected_args,
            expected_writes = {
                file.path: content
                for file, content in expected_writes.items()
            },
        )

    # Basic

    _add_test(
        name = "{}_basic".format(name),

        # Inputs
        buildfile_subidentifiers_files = [
            "some/buildfile_subidentifiers/0",
            "some/buildfile_subidentifiers/1",
        ],
        execution_root_file = "an/execution/root/file",
        install_path = "best/vision.xcodeproj",
        project_options = {
            "development_region": "en",
        },
        selected_model_versions_file = "some/selected_model_versions_file",
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # knownRegionsOutputPath
            _KNOWN_REGIONS_DECLARED_FILE.path,
            # filesAndGroupsOutputPath
            _FILES_AND_GROUPS_DECLARED_FILE.path,
            # resolvedRepositoriesOutputPath
            _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE.path,
            # workspace
            "/Users/TimApple/StarBoard",
            # installPath
            "best/vision.xcodeproj",
            # executionRootFile
            "an/execution/root/file",
            # selectedModelVersionsFile
            "some/selected_model_versions_file",
            # filePathsFile
            _FILE_PATHS_FILE.path,
            # folderPathsFile
            _FOLDER_PATHS_FILE.path,
            # developmentRegion
            "en",
            # useBaseInternationalization
            "--use-base-internationalization",
            # buildFileSubIdentifiersFiles
            "--build-file-sub-identifiers-files",
            "some/buildfile_subidentifiers/0",
            "some/buildfile_subidentifiers/1",
        ],
        expected_writes = {
            _FILE_PATHS_FILE: "\n",
            _FOLDER_PATHS_FILE: "\n",
        },
    )

    # Full

    _add_test(
        name = "{}_full".format(name),

        # Inputs
        buildfile_subidentifiers_files = [
            "some/buildfile_subidentifiers/0",
            "some/buildfile_subidentifiers/1",
        ],
        colorize = True,
        compile_stub_needed = True,
        execution_root_file = "an/execution/root/file",
        files = [
            "a/path/to/a/file",
            "another/path/to/another/file",
        ],
        file_paths = [
            "a/path/to/a/file_path.bundle",
            "another/path/to/another/file_path.framework",
        ],
        folders = [
            "a/path/to/a/folder",
            "another/path/to/another/folder",
        ],
        install_path = "best/vision.xcodeproj",
        project_options = {
            "development_region": "enGB",
        },
        selected_model_versions_file = "some/selected_model_versions_file",
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # knownRegionsOutputPath
            _KNOWN_REGIONS_DECLARED_FILE.path,
            # filesAndGroupsOutputPath
            _FILES_AND_GROUPS_DECLARED_FILE.path,
            # resolvedRepositoriesOutputPath
            _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE.path,
            # workspace
            "/Users/TimApple/StarBoard",
            # installPath
            "best/vision.xcodeproj",
            # executionRootFile
            "an/execution/root/file",
            # selectedModelVersionsFile
            "some/selected_model_versions_file",
            # filePathsFile
            _FILE_PATHS_FILE.path,
            # folderPathsFile
            _FOLDER_PATHS_FILE.path,
            # developmentRegion
            "enGB",
            # useBaseInternationalization
            "--use-base-internationalization",
            # compileStubNeeded
            "--compile-stub-needed",
            # buildFileSubIdentifiersFiles
            "--build-file-sub-identifiers-files",
            "some/buildfile_subidentifiers/0",
            "some/buildfile_subidentifiers/1",
            # colorize
            "--colorize",
        ],
        expected_writes = {
            _FILE_PATHS_FILE: """\
a/path/to/a/file
another/path/to/another/file
a/path/to/a/file_path.bundle
another/path/to/another/file_path.framework
""",
            _FOLDER_PATHS_FILE: """\
a/path/to/a/folder
another/path/to/another/folder
""",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
