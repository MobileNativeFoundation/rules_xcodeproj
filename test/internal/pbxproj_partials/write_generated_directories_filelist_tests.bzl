"""Tests for `pbxproj_partials.write_generated_directories_filelist`."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

_FILELIST_DECLARED_FILE = mock_actions.mock_file(
    "a_generator_name-generated_directories.filelist",
)

def _file(path, *, is_directory = False, is_source = False):
    return struct(
        dirname = paths.dirname(path),
        is_directory = is_directory,
        is_source = is_source,
        path = path,
    )

def _write_generated_directories_filelist_test_impl(ctx):
    env = unittest.begin(ctx)

    # Arrange

    actions = mock_actions.create()
    infoplists = [_file(path) for path in ctx.attr.infoplists]
    srcs = [
        _file(
            path,
            is_directory = path in ctx.attr.directory_srcs,
            is_source = path in ctx.attr.source_srcs,
        )
        for path in ctx.attr.srcs
    ]

    # Act

    filelist = pbxproj_partials.write_generated_directories_filelist(
        actions = actions.mock,
        generator_name = "a_generator_name",
        infoplists = infoplists,
        install_path = "a/project.xcodeproj",
        srcs = depset(srcs),
        tool = None,
    )

    # Assert

    asserts.equals(
        env,
        {
            _FILELIST_DECLARED_FILE: None,
        },
        actions.declared_files,
        "actions.declare_file",
    )

    asserts.equals(
        env,
        ctx.attr.expected_directories,
        actions.args_objects[0].captured.args,
        "args[0] arguments",
    )

    asserts.equals(
        env,
        [_FILELIST_DECLARED_FILE.path],
        actions.args_objects[1].captured.args,
        "args[1] arguments",
    )

    asserts.equals(
        env,
        _FILELIST_DECLARED_FILE,
        filelist,
        "filelist",
    )

    return unittest.end(env)

write_generated_directories_filelist_test = unittest.make(
    impl = _write_generated_directories_filelist_test_impl,
    attrs = {
        # Expected
        "expected_directories": attr.string_list(mandatory = True),

        # Inputs
        "directory_srcs": attr.string_list(mandatory = True),
        "infoplists": attr.string_list(mandatory = True),
        "source_srcs": attr.string_list(mandatory = True),
        "srcs": attr.string_list(mandatory = True),
    },
)

def write_generated_directories_filelist_test_suite(name):
    """Test suite for `pbxproj_partials.write_generated_directories_filelist`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,

            # Inputs
            directory_srcs = [],
            infoplists = [],
            source_srcs = [],
            srcs = [],

            # Expected
            expected_directories):
        test_names.append(name)

        write_generated_directories_filelist_test(
            name = name,
            directory_srcs = directory_srcs,
            infoplists = infoplists,
            source_srcs = source_srcs,
            srcs = srcs,
            expected_directories = expected_directories,
        )

    _add_test(
        name = "{}_files".format(name),
        infoplists = [
            "bazel-out/ios-sim/bin/App/Info.plist",
        ],
        source_srcs = [
            "Modules/App/Source.swift",
        ],
        srcs = [
            "bazel-out/ios-sim/bin/Modules/App/Generated.swift",
            "Modules/App/Source.swift",
        ],
        expected_directories = [
            "bazel-out/ios-sim/bin/App",
            "bazel-out/ios-sim/bin/Modules/App",
        ],
    )

    # A tree artifact (e.g. a directory of generated sources) is listed as
    # itself, since its files aren't known until it's built
    _add_test(
        name = "{}_tree_artifact".format(name),
        directory_srcs = [
            "bazel-out/ios-sim/bin/Modules/App/generated_sources",
        ],
        srcs = [
            "bazel-out/ios-sim/bin/Modules/App/generated_sources",
        ],
        expected_directories = [
            "bazel-out/ios-sim/bin/Modules/App/generated_sources",
        ],
    )

    native.test_suite(
        name = name,
        tests = test_names,
    )
