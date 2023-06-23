"""Tests for `pbxproj_partials.write_files_and_groups`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_KNOWN_REGIONS_DECLARED_FILE = "a_generator_name_pbxproj_partials/pbxproject_known_regions"
_FILES_AND_GROUPS_DECLARED_FILE = "a_generator_name_pbxproj_partials/files_and_groups"
_RESOLVED_REPOSITORIES_FILE_DECLARED_FILE = "a_generator_name_pbxproj_partials/resolved_repositories_file"

def _write_files_and_groups_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    args = []

    def _args_add_all(flag_or_values, values = None, *, map_each = None):
        if values != None:
            flag = flag_or_values
        else:
            flag = None
            values = flag_or_values

        if type(values) == "depset":
            values = values.to_list()

        if not values:
            return

        if flag:
            args.append(flag)

        if map_each:
            args.extend(["{}({})".format(map_each, value) for value in values])
        else:
            args.extend(values)

    use_param_file_args = {}

    def _args_use_param_file(param_file):
        use_param_file_args["use_param_file"] = param_file

    set_param_file_format_args = {}

    def _args_set_param_file_format(format):
        set_param_file_format_args["format"] = format

    action_args = struct(
        add = lambda *x: args.extend(x),
        add_all = _args_add_all,
        use_param_file = _args_use_param_file,
        set_param_file_format = _args_set_param_file_format,
    )

    run_args = {}

    def _action_run(*, arguments, inputs, outputs, **_kwargs):
        run_args["arguments"] = arguments
        run_args["inputs"] = inputs
        run_args["outputs"] = outputs

    declared_files = {}

    def _actions_declare_file(path):
        declared_files[path] = None
        return path

    actions = struct(
        args = lambda: action_args,
        declare_file = _actions_declare_file,
        run = _action_run,
    )

    expected_declared_files = {
        _KNOWN_REGIONS_DECLARED_FILE: None,
        _FILES_AND_GROUPS_DECLARED_FILE: None,
        _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE: None,
    }
    expected_inputs = [
        ctx.attr.execution_root_file,
        ctx.attr.selected_model_versions_file,
    ]

    # Act

    (
        pbxproject_known_regions,
        files_and_groups,
        resolved_repositories_file,
    ) = pbxproj_partials.write_files_and_groups(
        actions = actions,
        colorize = ctx.attr.colorize,
        execution_root_file = ctx.attr.execution_root_file,
        generator_name = "a_generator_name",
        files = depset(ctx.attr.files),
        file_paths = depset(ctx.attr.file_paths),
        folders = depset(ctx.attr.folders),
        project_options = ctx.attr.project_options,
        selected_model_versions_file = ctx.attr.selected_model_versions_file,
        tool = None,
        workspace_directory = ctx.attr.workspace_directory,
    )

    # Assert

    asserts.equals(
        env,
        expected_declared_files,
        declared_files,
        "actions.declare_file",
    )

    asserts.equals(
        env,
        "@%s",
        use_param_file_args["use_param_file"],
        "args.use_param_file",
    )

    asserts.equals(
        env,
        "multiline",
        set_param_file_format_args["format"],
        "args.param_file_format",
    )

    asserts.equals(
        env,
        [action_args],
        run_args["arguments"],
        "actions.run.arguments",
    )

    asserts.equals(
        env,
        ctx.attr.expected_args,
        args,
        "actions.run.arguments[0]",
    )

    asserts.equals(
        env,
        expected_inputs,
        run_args["inputs"],
        "actions.run.inputs",
    )

    asserts.equals(
        env,
        expected_declared_files.keys(),
        run_args["outputs"],
        "actions.run.outputs",
    )

    asserts.equals(
        env,
        _KNOWN_REGIONS_DECLARED_FILE,
        pbxproject_known_regions,
        "pbxproject_known_regions",
    )
    asserts.equals(
        env,
        _FILES_AND_GROUPS_DECLARED_FILE,
        files_and_groups,
        "files_and_groups",
    )
    asserts.equals(
        env,
        _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE,
        resolved_repositories_file,
        "resolved_repositories_file",
    )

    return unittest.end(env)

write_files_and_groups_test = unittest.make(
    impl = _write_files_and_groups_test_impl,
    attrs = {
        # Inputs
        "colorize": attr.bool(mandatory = True),
        "execution_root_file": attr.string(mandatory = True),
        "files": attr.string_list(mandatory = True),
        "file_paths": attr.string_list(mandatory = True),
        "folders": attr.string_list(mandatory = True),
        "project_options": attr.string_dict(mandatory = True),
        "selected_model_versions_file": attr.string(mandatory = True),
        "workspace_directory": attr.string(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
    },
)

def write_files_and_groups_test_suite(name):
    """Test suite for `pbxproj_partials.write_files_and_groups`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,

            # Inputs
            colorize = False,
            execution_root_file,
            files = [],
            file_paths = [],
            folders = [],
            project_options,
            selected_model_versions_file,
            workspace_directory,

            # Expected
            expected_args):
        test_names.append(name)
        write_files_and_groups_test(
            name = name,

            # Inputs
            colorize = colorize,
            execution_root_file = execution_root_file,
            files = files,
            file_paths = file_paths,
            folders = folders,
            project_options = project_options,
            selected_model_versions_file = selected_model_versions_file,
            workspace_directory = workspace_directory,

            # Expected
            expected_args = expected_args,
        )

    # Basic

    _add_test(
        name = "{}_basic".format(name),

        # Inputs
        execution_root_file = "an/execution/root/file",
        project_options = {
            "development_region": "en",
        },
        selected_model_versions_file = "some/selected_model_versions_file",
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # knownRegionsOutputPath
            _KNOWN_REGIONS_DECLARED_FILE,
            # filesAndGroupsOutputPath
            _FILES_AND_GROUPS_DECLARED_FILE,
            # resolvedRepositoriesOutputPath
            _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE,
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # selectedModelVersionsFile
            "some/selected_model_versions_file",
            # developmentRegion
            "en",
            # useBaseInternationalization
            "--use-base-internationalization",
        ],
    )

    # files

    _add_test(
        name = "{}_files".format(name),

        # Inputs
        execution_root_file = "an/execution/root/file",
        files = [
            "a/path/to/a/file",
            "another/path/to/another/file",
        ],
        project_options = {
            "development_region": "enGB",
        },
        selected_model_versions_file = "some/selected_model_versions_file",
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # knownRegionsOutputPath
            _KNOWN_REGIONS_DECLARED_FILE,
            # filesAndGroupsOutputPath
            _FILES_AND_GROUPS_DECLARED_FILE,
            # resolvedRepositoriesOutputPath
            _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE,
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # selectedModelVersionsFile
            "some/selected_model_versions_file",
            # developmentRegion
            "enGB",
            # useBaseInternationalization
            "--use-base-internationalization",
            # filePaths
            "--file-paths",
            "a/path/to/a/file",
            "another/path/to/another/file",
        ],
    )

    # file_paths

    _add_test(
        name = "{}_files_paths".format(name),

        # Inputs
        execution_root_file = "an/execution/root/file",
        file_paths = [
            "a/path/to/a/file_path.bundle",
            "another/path/to/another/file_path.framework",
        ],
        project_options = {
            "development_region": "enGB",
        },
        selected_model_versions_file = "some/selected_model_versions_file",
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # knownRegionsOutputPath
            _KNOWN_REGIONS_DECLARED_FILE,
            # filesAndGroupsOutputPath
            _FILES_AND_GROUPS_DECLARED_FILE,
            # resolvedRepositoriesOutputPath
            _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE,
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # selectedModelVersionsFile
            "some/selected_model_versions_file",
            # developmentRegion
            "enGB",
            # useBaseInternationalization
            "--use-base-internationalization",
            # filePaths
            "--file-paths",
            "a/path/to/a/file_path.bundle",
            "another/path/to/another/file_path.framework",
        ],
    )

    # folders

    _add_test(
        name = "{}_folders".format(name),

        # Inputs
        execution_root_file = "an/execution/root/file",
        folders = [
            "a/path/to/a/folder",
            "another/path/to/another/folder",
        ],
        project_options = {
            "development_region": "enGB",
        },
        selected_model_versions_file = "some/selected_model_versions_file",
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # knownRegionsOutputPath
            _KNOWN_REGIONS_DECLARED_FILE,
            # filesAndGroupsOutputPath
            _FILES_AND_GROUPS_DECLARED_FILE,
            # resolvedRepositoriesOutputPath
            _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE,
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # selectedModelVersionsFile
            "some/selected_model_versions_file",
            # developmentRegion
            "enGB",
            # useBaseInternationalization
            "--use-base-internationalization",
            # folderPaths
            "--folder-paths",
            "a/path/to/a/folder",
            "another/path/to/another/folder",
        ],
    )

    # Full

    _add_test(
        name = "{}_full".format(name),

        # Inputs
        colorize = True,
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
        project_options = {
            "development_region": "enGB",
        },
        selected_model_versions_file = "some/selected_model_versions_file",
        workspace_directory = "/Users/TimApple/StarBoard",

        # Expected
        expected_args = [
            # knownRegionsOutputPath
            _KNOWN_REGIONS_DECLARED_FILE,
            # filesAndGroupsOutputPath
            _FILES_AND_GROUPS_DECLARED_FILE,
            # resolvedRepositoriesOutputPath
            _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE,
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # selectedModelVersionsFile
            "some/selected_model_versions_file",
            # developmentRegion
            "enGB",
            # useBaseInternationalization
            "--use-base-internationalization",
            # filePaths
            "--file-paths",
            "a/path/to/a/file",
            "another/path/to/another/file",
            "a/path/to/a/file_path.bundle",
            "another/path/to/another/file_path.framework",
            # folderPaths
            "--folder-paths",
            "a/path/to/a/folder",
            "another/path/to/another/folder",
            # colorize
            "--colorize",
        ],
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
