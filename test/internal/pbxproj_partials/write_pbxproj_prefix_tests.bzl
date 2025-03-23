"""Tests for `pbxproj_partials.write_pbxproj_prefix`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")
load("//test:utils.bzl", "mock_apple_platform_to_platform_name")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_OUTPUT_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/pbxproj_prefix",
)
_POST_BUILD_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/post_build_script",
)
_PRE_BUILD_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_pbxproj_partials/pre_build_script",
)

def _write_pbxproj_prefix_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    actions = mock_actions.create()

    expected_declared_files = {
        _OUTPUT_DECLARED_FILE: None,
    }
    expected_inputs = [
        ctx.attr.execution_root_file,
        ctx.attr.resolved_repositories_file,
    ]
    if ctx.attr.pre_build_script:
        file = _PRE_BUILD_DECLARED_FILE
        expected_declared_files[file] = None
        expected_inputs.append(file)
    if ctx.attr.post_build_script:
        file = _POST_BUILD_DECLARED_FILE
        expected_declared_files[file] = None
        expected_inputs.append(file)

    # Act

    output = pbxproj_partials.write_pbxproj_prefix(
        actions = actions.mock,
        apple_platform_to_platform_name = mock_apple_platform_to_platform_name,
        colorize = ctx.attr.colorize,
        config = ctx.attr.config,
        default_xcode_configuration = ctx.attr.default_xcode_configuration,
        execution_root_file = ctx.attr.execution_root_file,
        generator_name = "a_generator_name",
        import_index_build_indexstores = (
            ctx.attr.import_index_build_indexstores
        ),
        index_import = ctx.attr.index_import,
        install_path = "a/project.xcodeproj",
        legacy_index_import = ctx.attr.legacy_index_import,
        minimum_xcode_version = ctx.attr.minimum_xcode_version,
        platforms = ctx.attr.platforms,
        post_build_script = ctx.attr.post_build_script,
        pre_build_script = ctx.attr.pre_build_script,
        project_options = ctx.attr.project_options,
        resolved_repositories_file = ctx.attr.resolved_repositories_file,
        target_ids_list = ctx.attr.target_ids_list,
        tool = None,
        workspace_directory = ctx.attr.workspace_directory,
        xcode_configurations = ctx.attr.xcode_configurations,
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
        [_OUTPUT_DECLARED_FILE],
        actions.run_args["outputs"],
        "actions.run.outputs",
    )

    asserts.equals(
        env,
        _OUTPUT_DECLARED_FILE,
        output,
        "output",
    )

    return unittest.end(env)

write_pbxproj_prefix_test = unittest.make(
    impl = _write_pbxproj_prefix_test_impl,
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "colorize": attr.bool(mandatory = True),
        "config": attr.string(mandatory = True),
        "default_xcode_configuration": attr.string(mandatory = True),
        "execution_root_file": attr.string(mandatory = True),
        "import_index_build_indexstores": attr.bool(mandatory = True),
        "index_import": attr.string(mandatory = True),
        "legacy_index_import": attr.string(mandatory = True),
        "minimum_xcode_version": attr.string(mandatory = True),
        "platforms": attr.string_list(mandatory = True),
        "post_build_script": attr.string(),
        "pre_build_script": attr.string(),
        "project_options": attr.string_dict(mandatory = True),
        "resolved_repositories_file": attr.string(mandatory = True),
        "target_ids_list": attr.string(mandatory = True),
        "workspace_directory": attr.string(mandatory = True),
        "xcode_configurations": attr.string_list(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
        "expected_writes": attr.string_dict(mandatory = True),
    },
)

def write_pbxproj_prefix_test_suite(name):
    """Test suite for `pbxproj_partials.write_pbxproj_prefix`.

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
            config,
            default_xcode_configuration,
            execution_root_file,
            import_index_build_indexstores,
            index_import,
            legacy_index_import,
            minimum_xcode_version,
            platforms,
            post_build_script = None,
            pre_build_script = None,
            project_options,
            resolved_repositories_file,
            target_ids_list,
            workspace_directory,
            xcode_configurations,

            # Expected
            expected_args,
            expected_writes = {}):
        test_names.append(name)
        write_pbxproj_prefix_test(
            name = name,

            # Inputs
            colorize = colorize,
            config = config,
            default_xcode_configuration = default_xcode_configuration,
            execution_root_file = execution_root_file,
            import_index_build_indexstores = import_index_build_indexstores,
            index_import = index_import,
            legacy_index_import = legacy_index_import,
            minimum_xcode_version = minimum_xcode_version,
            platforms = platforms,
            post_build_script = post_build_script,
            pre_build_script = pre_build_script,
            project_options = project_options,
            resolved_repositories_file = resolved_repositories_file,
            target_ids_list = target_ids_list,
            workspace_directory = workspace_directory,
            xcode_configurations = xcode_configurations,

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
        config = "rules_xcodeproj",
        default_xcode_configuration = "Debug",
        execution_root_file = "an/execution/root/file",
        import_index_build_indexstores = True,
        index_import = "some/path/to/index_import",
        legacy_index_import = "some/path/to/legacy/index_import",
        minimum_xcode_version = "14.2.1",
        platforms = [
            "MACOS",
            "IOS_DEVICE",
        ],
        project_options = {
            "development_region": "en",
        },
        resolved_repositories_file = "some/path/to/resolved_repositories_file",
        target_ids_list = "a/path/to/target_ids_list",
        workspace_directory = "/Users/TimApple/StarBoard",
        xcode_configurations = [
            "Release",
            "Debug",
        ],

        # Expected
        expected_args = [
            # outputPath
            _OUTPUT_DECLARED_FILE.path,
            # config
            "rules_xcodeproj",
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # targetIdsFile
            "a/path/to/target_ids_list",
            # legacyIndexImport
            "some/path/to/legacy/index_import",
            # indexImport
            "some/path/to/index_import",
            # resolvedRepositoriesFile
            "some/path/to/resolved_repositories_file",
            # customToolchainID
            "com.rules_xcodeproj.BazelRulesXcodeProj.16B40",
            # minimumXcodeVersion
            "14.2.1",
            # importIndexBuildIndexstores
            "1",
            # defaultXcodeConfiguration
            "Debug",
            # developmentRegion
            "en",
            # platforms
            "--platforms",
            "macosx",
            "iphoneos",
            # xcodeConfigurations
            "--xcode-configurations",
            "Release",
            "Debug",
        ],
    )

    # Full

    _add_test(
        name = "{}_full".format(name),

        # Inputs
        colorize = True,
        config = "custom_rxcp_config",
        default_xcode_configuration = "Release",
        execution_root_file = "an/execution/root/file",
        import_index_build_indexstores = False,
        index_import = "some/path/to/index_import",
        legacy_index_import = "some/path/to/legacy/index_import",
        platforms = [
            "MACOS",
            "IOS_DEVICE",
        ],
        post_build_script = "a post_build_script",
        pre_build_script = "a pre_build_script",
        project_options = {
            "development_region": "enGB",
            "organization_name": "MobileNativeFoundation 2",
        },
        minimum_xcode_version = "14.2.1",
        resolved_repositories_file = "some/path/to/resolved_repositories_file",
        target_ids_list = "a/path/to/target_ids_list",
        workspace_directory = "/Users/TimApple/StarBoard",
        xcode_configurations = [
            "Release",
            "Debug",
        ],

        # Expected
        expected_args = [
            # outputPath
            _OUTPUT_DECLARED_FILE.path,
            # config
            "custom_rxcp_config",
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # targetIdsFile
            "a/path/to/target_ids_list",
            # legacyIndexImport
            "some/path/to/legacy/index_import",
            # indexImport
            "some/path/to/index_import",
            # resolvedRepositoriesFile
            "some/path/to/resolved_repositories_file",
            # customToolchainID
            "com.rules_xcodeproj.BazelRulesXcodeProj.16B40",
            # minimumXcodeVersion
            "14.2.1",
            # importIndexBuildIndexstores
            "0",
            # defaultXcodeConfiguration
            "Release",
            # developmentRegion
            "enGB",
            # organizationName
            "--organization-name",
            "MobileNativeFoundation 2",
            # platforms
            "--platforms",
            "macosx",
            "iphoneos",
            # xcodeConfigurations
            "--xcode-configurations",
            "Release",
            "Debug",
            # preBuildScript
            "--pre-build-script",
            _PRE_BUILD_DECLARED_FILE.path,
            # postBuildScript
            "--post-build-script",
            _POST_BUILD_DECLARED_FILE.path,
            # colorize
            "--colorize",
        ],
        expected_writes = {
            _POST_BUILD_DECLARED_FILE: "a post_build_script",
            _PRE_BUILD_DECLARED_FILE: "a pre_build_script",
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
