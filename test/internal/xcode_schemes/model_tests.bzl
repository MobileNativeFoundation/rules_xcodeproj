"""Model Tests for `xcode_schemes`"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:bazel_labels.bzl",
    "make_bazel_labels",
)

# buildifier: disable=bzl-visibility
load(
    "//xcodeproj/internal:workspace_name_resolvers.bzl",
    "make_stub_workspace_name_resolvers",
)

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:xcode_schemes.bzl", "make_xcode_schemes")

workspace_name_resolvers = make_stub_workspace_name_resolvers()

bazel_labels = make_bazel_labels(
    workspace_name_resolvers = workspace_name_resolvers,
)

xcode_schemes = make_xcode_schemes(
    bazel_labels = bazel_labels,
)

def _scheme_test(ctx):
    env = unittest.begin(ctx)

    name = "Foo"
    build_action = xcode_schemes.build_action(["//Sources/Foo"])
    test_action = xcode_schemes.test_action(["//Tests/FooTests"])
    launch_action = xcode_schemes.launch_action("//Sources/App")

    actual = xcode_schemes.scheme(
        name = name,
        build_action = build_action,
        test_action = test_action,
        launch_action = launch_action,
    )
    expected = struct(
        name = name,
        build_action = build_action,
        test_action = test_action,
        launch_action = launch_action,
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

scheme_test = unittest.make(_scheme_test)

def _build_target_test(ctx):
    env = unittest.begin(ctx)

    actual = xcode_schemes.build_target("//Sources/Foo")
    expected = struct(
        label = bazel_labels.normalize("//Sources/Foo"),
        build_for = None,
    )
    asserts.equals(env, expected, actual, "no build_for")

    actual = xcode_schemes.build_target(
        "//Sources/Foo",
        xcode_schemes.build_for(),
    )
    expected = struct(
        label = bazel_labels.normalize("//Sources/Foo"),
        build_for = xcode_schemes.build_for(),
    )
    asserts.equals(env, expected, actual, "with build_for")

    return unittest.end(env)

build_target_test = unittest.make(_build_target_test)

def _build_for_test(ctx):
    env = unittest.begin(ctx)

    actual = xcode_schemes.build_for()
    expected = struct(
        running = None,
        testing = None,
        profiling = None,
        archiving = None,
        analyzing = None,
    )
    asserts.equals(env, expected, actual, "default")

    actual = xcode_schemes.build_for(
        running = True,
        testing = True,
        profiling = True,
        archiving = True,
        analyzing = True,
    )
    expected = struct(
        running = True,
        testing = True,
        profiling = True,
        archiving = True,
        analyzing = True,
    )
    asserts.equals(env, expected, actual, "all true")

    actual = xcode_schemes.build_for(
        running = False,
        testing = True,
        profiling = False,
        archiving = True,
        analyzing = False,
    )
    expected = struct(
        running = False,
        testing = True,
        profiling = False,
        archiving = True,
        analyzing = False,
    )
    asserts.equals(env, expected, actual, "mix it up")

    return unittest.end(env)

build_for_test = unittest.make(_build_for_test)

def _build_action_test(ctx):
    env = unittest.begin(ctx)

    targets = [
        xcode_schemes.build_target("//Sources/Foo"),
    ]
    actual = xcode_schemes.build_action(targets)

    expected = struct(
        targets = [
            xcode_schemes.build_target(bazel_labels.normalize("//Sources/Foo")),
        ],
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

build_action_test = unittest.make(_build_action_test)

def _test_action_test(ctx):
    env = unittest.begin(ctx)

    targets = ["//Tests/FooTests"]

    actual = xcode_schemes.test_action(targets)
    expected = struct(
        build_configuration_name = xcode_schemes.DEFAULT_BUILD_CONFIGURATION_NAME,
        targets = [bazel_labels.normalize(t) for t in targets],
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

test_action_test = unittest.make(_test_action_test)

def _launch_action_test(ctx):
    test_env = unittest.begin(ctx)

    target = "//Sources/App"
    args = ["my arg"]
    env = {"RELEASE_KRAKEN": "true"}
    working_directory = "/path/to/working/directory"

    actual = xcode_schemes.launch_action(
        target = target,
        args = args,
        env = env,
        working_directory = working_directory,
    )
    expected = struct(
        build_configuration_name = xcode_schemes.DEFAULT_BUILD_CONFIGURATION_NAME,
        target = bazel_labels.normalize(target),
        args = args,
        env = env,
        working_directory = working_directory,
    )
    asserts.equals(test_env, expected, actual)

    return unittest.end(test_env)

launch_action_test = unittest.make(_launch_action_test)

def model_test_suite(name):
    return unittest.suite(
        name,
        scheme_test,
        build_target_test,
        build_for_test,
        build_action_test,
        test_action_test,
        launch_action_test,
    )
