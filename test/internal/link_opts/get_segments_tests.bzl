"""Tests for `link_opts.get_segments()`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:link_opts.bzl", "link_opts")

def _get_segments_no_segments_test(ctx):
    env = unittest.begin(ctx)

    opts = []
    expected = {}
    actual = link_opts.get_segments(opts)
    asserts.equals(env, expected, actual)

    return unittest.end(env)

get_segments_no_segments_test = unittest.make(_get_segments_no_segments_test)

def _get_segments_with_segments_test(ctx):
    env = unittest.begin(ctx)

    opts = [
        "-Wl,-sectcreate,__TEXT,__info_plist,bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-fastbuild-ST-72fe7e1ef217/bin/examples/command_line/tool/tool.merged_infoplist-intermediates/Info.plist",
        "-Wl,-sectcreate,__TEXT,__foo,path/to/foo",
    ]
    expected = {
        "__TEXT": {
            "__foo": link_opts.create_section(
                name = "__foo",
                file = "path/to/foo",
            ),
            "__info_plist": link_opts.create_section(
                name = "__info_plist",
                file = "bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-fastbuild-ST-72fe7e1ef217/bin/examples/command_line/tool/tool.merged_infoplist-intermediates/Info.plist",
            ),
        },
    }
    actual = link_opts.get_segments(opts)
    asserts.equals(env, expected, actual)

    return unittest.end(env)

get_segments_with_segments_test = unittest.make(
    _get_segments_with_segments_test,
)

def _get_segments_passing_dict_test(ctx):
    env = unittest.begin(ctx)

    segments = {
        "__TEXT": {
            "__foo": link_opts.create_section(
                name = "__foo",
                file = "path/to/foo",
            ),
        },
    }
    expected = segments
    actual = link_opts.get_segments(segments)
    asserts.equals(env, expected, actual)

    return unittest.end(env)

get_segments_passing_dict_test = unittest.make(_get_segments_passing_dict_test)

def get_segments_test_suite(name):
    return unittest.suite(
        name,
        get_segments_no_segments_test,
        get_segments_with_segments_test,
        get_segments_passing_dict_test,
    )
