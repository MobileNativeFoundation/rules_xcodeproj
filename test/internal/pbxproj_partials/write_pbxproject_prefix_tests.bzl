"""Tests for `pbxproj_partials.write_pbxproject_prefix`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_DECLARED_OUTPUT_FILE = "_declared_output_file_"

def _write_pbxproject_prefix_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    expected_output = _DECLARED_OUTPUT_FILE

    args = []
    action_args = struct(
        add = lambda *x: args.extend(x),
    )

    run_args = {}

    def _action_run(*, arguments, inputs, outputs, **_kwargs):
        run_args["arguments"] = arguments
        run_args["inputs"] = inputs
        run_args["outputs"] = outputs

    actions = struct(
        args = lambda: action_args,
        declare_file = lambda _: expected_output,
        run = _action_run,
    )

    # Act

    output = pbxproj_partials.write_pbxproject_prefix(
        actions = actions,
        colorize = ctx.attr.colorize,
        execution_root_file = ctx.attr.execution_root_file,
        generator_name = "a_generator_name",
        minimum_xcode_version = ctx.attr.minimum_xcode_version,
        project_options = ctx.attr.project_options,
        tool = None,
        workspace_directory = ctx.attr.workspace_directory,
    )

    # Assert

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
        [ctx.attr.execution_root_file],
        run_args["inputs"],
        "actions.run.inputs",
    )

    asserts.equals(
        env,
        [expected_output],
        run_args["outputs"],
        "actions.run.outputs",
    )

    asserts.equals(
        env,
        expected_output,
        output,
        "output",
    )

    return unittest.end(env)

write_pbxproject_prefix_test = unittest.make(
    impl = _write_pbxproject_prefix_test_impl,
    attrs = {
        # Inputs
        "colorize": attr.bool(mandatory = True),
        "execution_root_file": attr.string(mandatory = True),
        "minimum_xcode_version": attr.string(mandatory = True),
        "project_options": attr.string_dict(mandatory = True),
        "workspace_directory": attr.string(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
    },
)

def write_pbxproject_prefix_test_suite(name):
    """Test suite for `pbxproj_partials.write_pbxproject_prefix`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,
            colorize = False,
            execution_root_file,
            minimum_xcode_version,
            project_options,
            workspace_directory,
            expected_args):
        test_names.append(name)
        write_pbxproject_prefix_test(
            # Inputs
            name = name,
            colorize = colorize,
            execution_root_file = execution_root_file,
            minimum_xcode_version = minimum_xcode_version,
            project_options = project_options,
            workspace_directory = workspace_directory,

            # Expected
            expected_args = expected_args,
        )

    # Basic

    _add_test(
        name = "{}_basic".format(name),
        execution_root_file = "an/execution/root/file",
        minimum_xcode_version = "14.2.1",
        project_options = {
            "development_region": "en",
        },
        workspace_directory = "/Users/TimApple/StarBoard",
        expected_args = [
            # outputPath
            _DECLARED_OUTPUT_FILE,
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # minimumXcodeVersion
            "14.2.1",
            # developmentRegion
            "en",
        ],
    )

    # Full

    _add_test(
        name = "{}_full".format(name),
        colorize = True,
        execution_root_file = "an/execution/root/file",
        project_options = {
            "development_region": "enGB",
            "organization_name": "MobileNativeFoundation 2",
        },
        minimum_xcode_version = "14.2.1",
        workspace_directory = "/Users/TimApple/StarBoard",
        expected_args = [
            # outputPath
            _DECLARED_OUTPUT_FILE,
            # workspace
            "/Users/TimApple/StarBoard",
            # executionRootFile
            "an/execution/root/file",
            # minimumXcodeVersion
            "14.2.1",
            # developmentRegion
            "enGB",
            # organizationName
            "--organization-name",
            "MobileNativeFoundation 2",
            # colorize
            "--colorize",
        ],
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
