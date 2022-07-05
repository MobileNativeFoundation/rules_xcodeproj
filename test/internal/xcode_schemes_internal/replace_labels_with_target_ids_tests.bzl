"""Tests for `xcode_schemes_internal.replace_labels_with_target_ids`"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:target_id.bzl", "get_id")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:xcode_schemes_internal.bzl", "xcode_schemes_internal")

_CONFIGURATION = "darwin_x86_64-fastbuild-ST-d53d69b6b8c1"

def _all_actions_specified_test(ctx):
    env = unittest.begin(ctx)

    name = "Foo"
    args = ["my arg"]
    la_env = {"RELEASE_KRAKEN": "true"}
    working_directory = "/path/to/working/directory"

    scheme = xcode_schemes_internal.scheme(
        name = name,
        build_action = xcode_schemes_internal.build_action(
            targets = ["//Sources/Foo:Foo"],
        ),
        test_action = xcode_schemes_internal.test_action(
            targets = ["//Tests/FooTests:FooTests"],
        ),
        launch_action = xcode_schemes_internal.launch_action(
            target = "//Sources/App:App",
            args = args,
            env = la_env,
            working_directory = working_directory,
        ),
    )
    actual = xcode_schemes_internal.replace_labels_with_target_ids(
        scheme = scheme,
        configuration = _CONFIGURATION,
    )
    expected = xcode_schemes_internal.scheme(
        name = name,
        build_action = xcode_schemes_internal.build_action(
            targets = [
                get_id(
                    label = "//Sources/Foo:Foo",
                    configuration = _CONFIGURATION,
                ),
            ],
        ),
        test_action = xcode_schemes_internal.test_action(
            targets = [
                get_id(
                    label = "//Tests/FooTests:FooTests",
                    configuration = _CONFIGURATION,
                ),
            ],
        ),
        launch_action = xcode_schemes_internal.launch_action(
            target = get_id(
                label = "//Sources/App:App",
                configuration = _CONFIGURATION,
            ),
            args = args,
            env = la_env,
            working_directory = working_directory,
        ),
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

all_actions_specified_test = unittest.make(_all_actions_specified_test)

def _no_actions_specified_test(ctx):
    env = unittest.begin(ctx)

    scheme = xcode_schemes_internal.scheme(name = "Foo")
    actual = xcode_schemes_internal.replace_labels_with_target_ids(
        scheme = scheme,
        configuration = _CONFIGURATION,
    )
    expected = scheme
    asserts.equals(env, expected, actual)

    return unittest.end(env)

no_actions_specified_test = unittest.make(_no_actions_specified_test)

def replace_labels_with_target_ids_test_suite(name):
    return unittest.suite(
        name,
        all_actions_specified_test,
        no_actions_specified_test,
    )
