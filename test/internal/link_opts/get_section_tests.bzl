"""Tests for `link_opts.get_section()`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:link_opts.bzl", "link_opts")

def _get_section_segment_does_not_exist_test(ctx):
    env = unittest.begin(ctx)

    segments = {
        "__TEXT": {
            "__foo": link_opts.create_section(
                name = "__foo",
                file = "path/to/foo",
            ),
        },
    }
    expected = None
    actual = link_opts.get_section(
        segments,
        "__DOES_NOT_EXIST",
        "__section_name",
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

get_section_segment_does_not_exist_test = unittest.make(
    _get_section_segment_does_not_exist_test,
)

def _get_section_section_does_not_exist_test(ctx):
    env = unittest.begin(ctx)

    segments = {
        "__TEXT": {
            "__foo": link_opts.create_section(
                name = "__foo",
                file = "path/to/foo",
            ),
        },
    }
    expected = None
    actual = link_opts.get_section(segments, "__TEXT", "__bar")
    asserts.equals(env, expected, actual)

    return unittest.end(env)

get_section_section_does_not_exist_test = unittest.make(
    _get_section_section_does_not_exist_test,
)

def _get_section_section_exists_test(ctx):
    env = unittest.begin(ctx)

    section = link_opts.create_section(
        name = "__foo",
        file = "path/to/foo",
    )
    segments = {
        "__TEXT": {
            "__foo": section,
        },
    }
    expected = section
    actual = link_opts.get_section(segments, "__TEXT", "__foo")
    asserts.equals(env, expected, actual)

    return unittest.end(env)

get_section_section_exists_test = unittest.make(
    _get_section_section_exists_test,
)

def get_section_test_suite(name):
    return unittest.suite(
        name,
        get_section_segment_does_not_exist_test,
        get_section_section_does_not_exist_test,
        get_section_section_exists_test,
    )
