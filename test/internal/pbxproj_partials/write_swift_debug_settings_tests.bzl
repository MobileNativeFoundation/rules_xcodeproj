"""Tests for `pbxproj_partials.write_swift_debug_settings`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_SWIFT_DEBUG_SETTINGS_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name_swift_debug_settings/A_CONFIG-swift_debug_settings.py",
)

def _write_swift_debug_settings_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    top_level_swift_debug_settings = [
        mock_actions.mock_file(f)
        for f in ctx.attr.top_level_swift_debug_settings
    ]

    actions = mock_actions.create()

    expected_declared_files = {
        _SWIFT_DEBUG_SETTINGS_DECLARED_FILE: None,
    }
    expected_inputs = top_level_swift_debug_settings
    expected_outputs = [
        _SWIFT_DEBUG_SETTINGS_DECLARED_FILE,
    ]

    # Act

    output = pbxproj_partials.write_swift_debug_settings(
        actions = actions.mock,
        colorize = ctx.attr.colorize,
        generator_name = "a_generator_name",
        install_path = "a/project.xcodeproj",
        tool = None,
        top_level_swift_debug_settings = [
            ("KEY_" + f.path, f)
            for f in top_level_swift_debug_settings
        ],
        xcode_configuration = "A_CONFIG",
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
        _SWIFT_DEBUG_SETTINGS_DECLARED_FILE,
        output,
        "output",
    )

    return unittest.end(env)

write_swift_debug_settings_test = unittest.make(
    impl = _write_swift_debug_settings_test_impl,
    # @unsorted-dict-items
    attrs = {
        # Inputs
        "colorize": attr.bool(mandatory = True),
        "top_level_swift_debug_settings": attr.string_list(mandatory = True),

        # Expected
        "expected_args": attr.string_list(mandatory = True),
    },
)

def write_swift_debug_settings_test_suite(name):
    """Test suite for `pbxproj_partials.write_swift_debug_settings`.

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
            top_level_swift_debug_settings,

            # Expected
            expected_args):
        test_names.append(name)
        write_swift_debug_settings_test(
            name = name,

            # Inputs
            colorize = colorize,
            top_level_swift_debug_settings = top_level_swift_debug_settings,

            # Expected
            expected_args = expected_args,
        )

    # Full

    _add_test(
        name = "{}_full".format(name),

        # Inputs
        colorize = True,
        top_level_swift_debug_settings = [
            "transitive_settings/2",
            "transitive_settings/1",
        ],

        # Expected
        expected_args = [
            # colorize
            "1",
            # outputPath
            _SWIFT_DEBUG_SETTINGS_DECLARED_FILE.path,
            # keysAndFiles
            "KEY_transitive_settings/2",
            "transitive_settings/2",
            "KEY_transitive_settings/1",
            "transitive_settings/1",
        ],
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
