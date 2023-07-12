"""Tests for `pbxproj_partials.write_pbxproj_prefix`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_OUTPUT_DECLARED_FILE = "a_generator_name_pbxproj_partials/pbxproj_prefix"
_POST_BUILD_DECLARED_FILE = "a_generator_name_pbxproj_partials/post_build_script"
_PRE_BUILD_DECLARED_FILE = "a_generator_name_pbxproj_partials/pre_build_script"

def _write_pbxproj_prefix_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    args = []

    def _args_add_all(flag, values, *, map_each = None):
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

    writes = {}

    def _actions_write(write_output, args):
        writes[write_output] = args

    actions = struct(
        args = lambda: action_args,
        declare_file = _actions_declare_file,
        run = _action_run,
        write = _actions_write,
    )

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
        actions = actions,
        build_mode = ctx.attr.build_mode,
        colorize = ctx.attr.colorize,
        default_xcode_configuration = ctx.attr.default_xcode_configuration,
        execution_root_file = ctx.attr.execution_root_file,
        generator_name = "a_generator_name",
        index_import = ctx.attr.index_import,
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
        declared_files,
        "actions.declare_file",
    )

    asserts.equals(
        env,
        ctx.attr.expected_writes,
        writes,
        "actions.write",
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
        [_OUTPUT_DECLARED_FILE],
        run_args["outputs"],
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
    attrs = {
        # Inputs
        "colorize": attr.bool(mandatory = True),
        "build_mode": attr.string(mandatory = True),
        "default_xcode_configuration": attr.string(),
        "execution_root_file": attr.string(mandatory = True),
        "index_import": attr.string(mandatory = True),
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
            build_mode,
            colorize = False,
            default_xcode_configuration = None,
            execution_root_file,
            index_import,
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
            build_mode = build_mode,
            colorize = colorize,
            default_xcode_configuration = default_xcode_configuration,
            execution_root_file = execution_root_file,
            index_import = index_import,
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
            expected_writes = expected_writes,
        )

    # Basic

    _add_test(
        name = "{}_basic".format(name),

        # Inputs
        build_mode = "xcode",
        execution_root_file = "an/execution/root/file",
        index_import = "some/path/to/index_import",
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
            _OUTPUT_DECLARED_FILE,
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # targetIdsFile
            "a/path/to/target_ids_list",
            # indexImport
            "some/path/to/index_import",
            # resolvedRepositoriesFile
            "some/path/to/resolved_repositories_file",
            # buildMode
            "xcode",
            # minimumXcodeVersion
            "14.2.1",
            # developmentRegion
            "en",
            # platforms
            "--platforms",
            "<function _apple_platform_to_platform_name from //xcodeproj/internal:pbxproj_partials.bzl>(MACOS)",
            "<function _apple_platform_to_platform_name from //xcodeproj/internal:pbxproj_partials.bzl>(IOS_DEVICE)",
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
        build_mode = "bazel",
        colorize = True,
        default_xcode_configuration = "Debug",
        execution_root_file = "an/execution/root/file",
        index_import = "some/path/to/index_import",
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
            _OUTPUT_DECLARED_FILE,
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # targetIdsFile
            "a/path/to/target_ids_list",
            # indexImport
            "some/path/to/index_import",
            # resolvedRepositoriesFile
            "some/path/to/resolved_repositories_file",
            # buildMode
            "bazel",
            # minimumXcodeVersion
            "14.2.1",
            # developmentRegion
            "enGB",
            # organizationName
            "--organization-name",
            "MobileNativeFoundation 2",
            # platforms
            "--platforms",
            "<function _apple_platform_to_platform_name from //xcodeproj/internal:pbxproj_partials.bzl>(MACOS)",
            "<function _apple_platform_to_platform_name from //xcodeproj/internal:pbxproj_partials.bzl>(IOS_DEVICE)",
            # xcodeConfigurations
            "--xcode-configurations",
            "Release",
            "Debug",
            # defaultXcodeConfiguration
            "--default-xcode-configuration",
            "Debug",
            # preBuildScript
            "--pre-build-script",
            _PRE_BUILD_DECLARED_FILE,
            # postBuildScript
            "--post-build-script",
            _POST_BUILD_DECLARED_FILE,
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
