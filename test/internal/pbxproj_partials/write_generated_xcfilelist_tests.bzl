"""Tests for `pbxproj_partials.write_generated_xcfilelist`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_GENERATED_XCFILELIST_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name-generated.xcfilelist",
)

def _write_generated_xcfilelist_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    actions = mock_actions.create()
    infoplists = [
        mock_actions.mock_file(path)
        for path in ctx.attr.infoplists
    ]
    srcs = [
        struct(
            path = path,
            is_source = path in ctx.attr.source_srcs,
        )
        for path in ctx.attr.srcs
    ]

    # Act

    generated_xcfilelist = pbxproj_partials.write_generated_xcfilelist(
        actions = actions.mock,
        generator_name = "a_generator_name",
        infoplists = infoplists,
        srcs = depset(srcs),
    )

    # Assert

    asserts.equals(
        env,
        {
            _GENERATED_XCFILELIST_DECLARED_FILE: None,
        },
        actions.declared_files,
        "actions.declare_file",
    )

    asserts.equals(
        env,
        {
            _GENERATED_XCFILELIST_DECLARED_FILE.path: ctx.attr.expected_content,
        },
        actions.writes,
        "actions.write",
    )

    asserts.equals(
        env,
        "multiline",
        actions.args_objects[0].captured.set_param_file_format_args["format"],
        "args[0].param_file_format",
    )

    asserts.equals(
        env,
        _GENERATED_XCFILELIST_DECLARED_FILE,
        generated_xcfilelist,
        "generated_xcfilelist",
    )

    return unittest.end(env)

write_generated_xcfilelist_test = unittest.make(
    impl = _write_generated_xcfilelist_test_impl,
    attrs = {
        # Inputs
        "infoplists": attr.string_list(mandatory = True),
        "source_srcs": attr.string_list(mandatory = True),
        "srcs": attr.string_list(mandatory = True),

        # Expected
        "expected_content": attr.string(mandatory = True),
    },
)

def write_generated_xcfilelist_test_suite(name):
    """Test suite for `pbxproj_partials.write_generated_xcfilelist`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,

            # Inputs
            infoplists = [],
            source_srcs = [],
            srcs = [],

            # Expected
            expected_content):
        test_name = "{}_{}".format(name, len(test_names))
        test_names.append(test_name)

        write_generated_xcfilelist_test(
            name = test_name,
            infoplists = infoplists,
            source_srcs = source_srcs,
            srcs = srcs,
            expected_content = expected_content,
        )

    _add_test(
        name = "deduplicates_generated_paths",
        infoplists = [
            "bazel-out/ios-sim/bin/App/Info.plist",
        ],
        source_srcs = [
            "Modules/App/Source.swift",
        ],
        srcs = [
            "bazel-out/ios-sim/bin/Modules/App/Shared.generated.swift",
            "Modules/App/Source.swift",
            "bazel-out/ios-sim/bin/Modules/App/Shared.generated.swift",
            "bazel-out/ios-sim/bin/Modules/App/Other.generated.swift",
        ],
        expected_content = """\
$(BAZEL_OUT)/ios-sim/bin/App/Info.plist
$(BAZEL_OUT)/ios-sim/bin/Modules/App/Shared.generated.swift
$(BAZEL_OUT)/ios-sim/bin/Modules/App/Other.generated.swift
""",
    )

    _add_test(
        name = "empty",
        expected_content = "\n",
    )

    native.test_suite(
        name = name,
        tests = test_names,
    )
