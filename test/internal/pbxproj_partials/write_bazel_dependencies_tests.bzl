"""Tests for `pbxproj_partials.write_bazel_dependencies`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_OUTPUT_DECLARED_FILE = "a_generator_name_pbxproj_partials/bazel_dependencies"
_POST_BUILD_DECLARED_FILE = "a_generator_name_pbxproj_partials/post_build_script"
_PRE_BUILD_DECLARED_FILE = "a_generator_name_pbxproj_partials/pre_build_script"

def _write_bazel_dependencies_test_impl(ctx):
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
    expected_inputs = []
    if ctx.attr.pre_build_script:
        file = _PRE_BUILD_DECLARED_FILE
        expected_declared_files[file] = None
        expected_inputs.append(file)
    if ctx.attr.post_build_script:
        file = _POST_BUILD_DECLARED_FILE
        expected_declared_files[file] = None
        expected_inputs.append(file)

    # Act

    output = pbxproj_partials.write_bazel_dependencies(
        actions = actions,
        colorize = ctx.attr.colorize,
        default_xcode_configuration = ctx.attr.default_xcode_configuration,
        generator_name = "a_generator_name",
        index_import = ctx.attr.index_import,
        platforms = ctx.attr.platforms,
        post_build_script = ctx.attr.post_build_script,
        pre_build_script = ctx.attr.pre_build_script,
        target_ids_list = ctx.attr.target_ids_list,
        tool = None,
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

write_bazel_dependencies_test = unittest.make(
    impl = _write_bazel_dependencies_test_impl,
    attrs = {
        # Inputs
        "colorize": attr.bool(mandatory = True),
        "default_xcode_configuration": attr.string(),
        "index_import": attr.string(mandatory = True),
        "platforms": attr.string_list(mandatory = True),
        "post_build_script": attr.string(),
        "pre_build_script": attr.string(),
        "target_ids_list": attr.string(mandatory = True),
        "xcode_configurations": attr.string_list(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
        "expected_writes": attr.string_dict(mandatory = True),
    },
)

def write_bazel_dependencies_test_suite(name):
    """Test suite for `pbxproj_partials.write_bazel_dependencies`.

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
            default_xcode_configuration = None,
            index_import,
            platforms,
            post_build_script = None,
            pre_build_script = None,
            target_ids_list,
            xcode_configurations,

            # Expected
            expected_args,
            expected_writes = {}):
        test_names.append(name)
        write_bazel_dependencies_test(
            name = name,

            # Inputs
            colorize = colorize,
            default_xcode_configuration = default_xcode_configuration,
            index_import = index_import,
            platforms = platforms,
            post_build_script = post_build_script,
            pre_build_script = pre_build_script,
            target_ids_list = target_ids_list,
            xcode_configurations = xcode_configurations,

            # Expected
            expected_args = expected_args,
            expected_writes = expected_writes,
        )

    # Basic

    _add_test(
        name = "{}_basic".format(name),

        # Inputs
        index_import = "some/path/to/index_import",
        platforms = [
            "MACOS",
            "IOS",
        ],
        target_ids_list = "a/path/to/target_ids_list",
        xcode_configurations = [
            "Release",
            "Debug",
        ],

        # Expected
        expected_args = [
            # outputPath
            _OUTPUT_DECLARED_FILE,
            # targetIdsFile
            "a/path/to/target_ids_list",
            # indexImport
            "some/path/to/index_import",
            # xcodeConfigurations
            "--xcode-configurations",
            "Release",
            "Debug",
            # platforms
            "--platforms",
            "<function _apple_platform_to_platform_name from //xcodeproj/internal:pbxproj_partials.bzl>(MACOS)",
            "<function _apple_platform_to_platform_name from //xcodeproj/internal:pbxproj_partials.bzl>(IOS)",
        ],
    )

    # Full

    _add_test(
        name = "{}_full".format(name),

        # Inputs
        colorize = True,
        default_xcode_configuration = "Debug",
        index_import = "some/path/to/index_import",
        platforms = [
            "MACOS",
            "IOS",
        ],
        post_build_script = "a post_build_script",
        pre_build_script = "a pre_build_script",
        target_ids_list = "a/path/to/target_ids_list",
        xcode_configurations = [
            "Release",
            "Debug",
        ],

        # Expected
        expected_args = [
            # outputPath
            _OUTPUT_DECLARED_FILE,
            # targetIdsFile
            "a/path/to/target_ids_list",
            # indexImport
            "some/path/to/index_import",
            # xcodeConfigurations
            "--xcode-configurations",
            "Release",
            "Debug",
            # defaultXcodeConfiguration
            "--default-xcode-configuration",
            "Debug",
            # platforms
            "--platforms",
            "<function _apple_platform_to_platform_name from //xcodeproj/internal:pbxproj_partials.bzl>(MACOS)",
            "<function _apple_platform_to_platform_name from //xcodeproj/internal:pbxproj_partials.bzl>(IOS)",
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
