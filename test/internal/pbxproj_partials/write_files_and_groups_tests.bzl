"""Tests for `pbxproj_partials.write_files_and_groups`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_KNOWN_REGIONS_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/pbxproject_known_regions",
)
_FILES_AND_GROUPS_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/files_and_groups",
)
_RESOLVED_REPOSITORIES_FILE_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/resolved_repositories_file",
)
_FILE_PATHS_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/file_paths_file",
)
_GENERATED_FILE_PATHS_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/generated_file_paths_file",
)

def _write_files_and_groups_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    actions = mock_actions.create()

    expected_declared_files = {
        _FILES_AND_GROUPS_DECLARED_FILE: None,
        _KNOWN_REGIONS_DECLARED_FILE: None,
        _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE: None,
        _FILE_PATHS_FILE: None,
        _GENERATED_FILE_PATHS_FILE: None,
    }
    expected_inputs = [
        _FILE_PATHS_FILE,
        _GENERATED_FILE_PATHS_FILE,
        ctx.attr.execution_root_file,
        ctx.attr.selected_model_versions_file,
    ] + ctx.attr.buildfile_subidentifiers_files
    expected_outputs = [
        _FILES_AND_GROUPS_DECLARED_FILE,
        _KNOWN_REGIONS_DECLARED_FILE,
        _RESOLVED_REPOSITORIES_FILE_DECLARED_FILE,
    ]

    files = [
        struct(
            path = path,
            is_source = True,
        )
        for path in ctx.attr.files
    ] + [
        struct(
            path = path,
            is_source = False,
            owner = mock_actions.mock_label(owner),
        )
        for (path, owner) in ctx.attr.generated_files.items()
    ]
    generated_file_paths = [
        struct(
            path = path,
            owner = mock_actions.mock_label(owner),
        )
        for (path, owner) in ctx.attr.generated_file_paths.items()
    ]

    # Act

    (
        pbxproject_known_regions,
        files_and_groups,
        resolved_repositories_file,
    ) = pbxproj_partials.write_files_and_groups(
        actions = actions.mock,
        buildfile_subidentifiers_files = (
            ctx.attr.buildfile_subidentifiers_files
        ),
        colorize = ctx.attr.colorize,
        compile_stub_needed = ctx.attr.compile_stub_needed,
        execution_root_file = ctx.attr.execution_root_file,
        files = depset(files),
        file_paths = depset(ctx.attr.file_paths),
        generated_file_paths = depset(generated_file_paths),
        generator_name = "a_generator_name",
        install_path = ctx.attr.install_path,
        project_options = ctx.attr.project_options,
        selected_model_versions_file = ctx.attr.selected_model_versions_file,
        tool = None,
        workspace_directory = ctx.attr.workspace_directory,
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
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "buildfile_subidentifiers_files": attr.string_list(mandatory = True),
        "colorize": attr.bool(mandatory = True),
        "compile_stub_needed": attr.bool(mandatory = True),
        "execution_root_file": attr.string(mandatory = True),
        "file_paths": attr.string_list(mandatory = True),
        "files": attr.string_list(mandatory = True),
        "generated_file_paths": attr.string_dict(mandatory = True),
        "generated_files": attr.string_dict(mandatory = True),
        "install_path": attr.string(mandatory = True),
        "project_options": attr.string_dict(mandatory = True),
        "selected_model_versions_file": attr.string(mandatory = True),
        "workspace_directory": attr.string(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
        "expected_writes": attr.string_dict(mandatory = True),
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
            buildfile_subidentifiers_files,
            colorize = False,
            compile_stub_needed = False,
            execution_root_file,
            files = [],
            file_paths = [],
            generated_file_paths = {},
            generated_files = {},
            install_path,
            project_options,
            selected_model_versions_file,
            workspace_directory,

            # Expected
            expected_args,
            expected_writes):
        test_names.append(name)
        write_files_and_groups_test(
            name = name,

            # Inputs
            buildfile_subidentifiers_files = buildfile_subidentifiers_files,
            colorize = colorize,
            compile_stub_needed = compile_stub_needed,
            execution_root_file = execution_root_file,
            files = files,
            file_paths = file_paths,
            generated_file_paths = generated_file_paths,
            generated_files = generated_files,
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
            # indentWidth
            "",
            # tabWidth
            "",
            # usesTabs
            "",
            # filePathsFile
            _FILE_PATHS_FILE.path,
            # generatedFilePathsFile
            _GENERATED_FILE_PATHS_FILE.path,
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
            _GENERATED_FILE_PATHS_FILE: "\n",
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
        # @unsorted-dict-items
        generated_file_paths = {
            "bazel-out/ios-sim-config/bin/a/path/to/a/generated/file_as_file_path": "//a/path/to/a/generated",
            "bazel-out/ios-sim-config/bin/another/path/to/another/generated/file_as_file_path": "//another/path/to/another/generated",
            "bazel-out/ios-sim-config/bin/a/path/to/a/generated/some.framework": "//a/path/to/a/generated",
            "bazel-out/ios-sim-config/bin/another/path/to/another/generated/another.bundle": "//another/path/to/another/generated",
        },
        # @unsorted-dict-items
        generated_files = {
            "bazel-out/ios-sim-config/bin/a/path/to/a/generated/file": "//a/path/to/a/generated",
            "bazel-out/ios-sim-config/bin/another/path/to/another/generated/file": "//another/path/to/another/generated",
        },
        install_path = "best/vision.xcodeproj",
        project_options = {
            "development_region": "enGB",
            "indent_width": "2",
            "tab_width": "3",
            "uses_tabs": "0",
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
            # indentWidth
            "2",
            # tabWidth
            "3",
            # usesTabs
            "0",
            # filePathsFile
            _FILE_PATHS_FILE.path,
            # generatedFilePathsFile
            _GENERATED_FILE_PATHS_FILE.path,
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
            _GENERATED_FILE_PATHS_FILE: """\
file
a/path/to/a/generated
ios-sim-config
file
another/path/to/another/generated
ios-sim-config
file_as_file_path
a/path/to/a/generated
ios-sim-config
file_as_file_path
another/path/to/another/generated
ios-sim-config
some.framework
a/path/to/a/generated
ios-sim-config
another.bundle
another/path/to/another/generated
ios-sim-config
""",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
