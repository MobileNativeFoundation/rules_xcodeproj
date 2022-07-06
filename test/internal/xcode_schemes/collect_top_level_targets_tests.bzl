"""Tests for `xcode_schemes.collect_top_level_targets`"""

load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:bazel_labels.bzl", "make_bazel_labels")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:workspace_name_resolvers.bzl",
    "make_stub_workspace_name_resolvers",
)

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:xcode_schemes.bzl", "make_xcode_schemes")

bazel_labels = make_bazel_labels(
    workspace_name_resolvers = make_stub_workspace_name_resolvers(),
)

xcode_schemes = make_xcode_schemes(bazel_labels = bazel_labels)

def _empty_schemes_list_test(ctx):
    env = unittest.begin(ctx)

    actual = xcode_schemes.collect_top_level_targets([])
    expected = sets.make()
    asserts.true(env, sets.is_equal(expected, actual))

    return unittest.end(env)

empty_schemes_list_test = unittest.make(_empty_schemes_list_test)

def _no_top_level_targets_test(ctx):
    env = unittest.begin(ctx)

    schemes = [
        xcode_schemes.scheme(
            name = "Foo",
        ),
    ]

    actual = xcode_schemes.collect_top_level_targets(schemes)
    expected = sets.make()
    asserts.true(env, sets.is_equal(expected, actual))

    return unittest.end(env)

no_top_level_targets_test = unittest.make(_no_top_level_targets_test)

def _single_scheme_test(ctx):
    env = unittest.begin(ctx)

    schemes = [
        xcode_schemes.scheme(
            name = "App",
            build_action = xcode_schemes.build_action(["//Do/Not/Find/Me"]),
            test_action = xcode_schemes.test_action([
                "//Tests/FooTests",
                "//Tests/BarTests",
            ]),
            launch_action = xcode_schemes.launch_action("//Sources/App"),
        ),
    ]
    actual = xcode_schemes.collect_top_level_targets(schemes)
    expected = sets.make([
        "//Sources/App:App",
        "//Tests/BarTests:BarTests",
        "//Tests/FooTests:FooTests",
    ])
    asserts.true(env, sets.is_equal(expected, actual))

    return unittest.end(env)

single_scheme_test = unittest.make(_single_scheme_test)

def _list_of_schemes_test(ctx):
    env = unittest.begin(ctx)

    schemes = [
        xcode_schemes.scheme(
            name = "App",
            build_action = xcode_schemes.build_action(["//Do/Not/Find/Me"]),
            test_action = xcode_schemes.test_action([
                "//Tests/FooTests",
                "//Tests/BarTests",
            ]),
            launch_action = xcode_schemes.launch_action("//Sources/App"),
        ),
        xcode_schemes.scheme(
            name = "Foo",
            build_action = xcode_schemes.build_action(["//Sources/Foo"]),
            test_action = xcode_schemes.test_action([
                "//Tests/FooTests",
                "//Tests/HelloTests",
            ]),
        ),
    ]
    actual = xcode_schemes.collect_top_level_targets(schemes)
    expected = sets.make([
        "//Sources/App:App",
        "//Tests/BarTests:BarTests",
        "//Tests/FooTests:FooTests",
        "//Tests/HelloTests:HelloTests",
    ])
    asserts.true(env, sets.is_equal(expected, actual))

    return unittest.end(env)

list_of_schemes_test = unittest.make(_list_of_schemes_test)

def collect_top_level_targets_test_suite(name):
    return unittest.suite(
        name,
        empty_schemes_list_test,
        no_top_level_targets_test,
        single_scheme_test,
        list_of_schemes_test,
    )
