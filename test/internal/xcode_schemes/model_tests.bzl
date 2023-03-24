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

    name = "//Foo:Foo"
    build_action = xcode_schemes.build_action(["//Sources/Foo"])
    launch_action = xcode_schemes.launch_action("//Sources/App")
    profile_action = xcode_schemes.launch_action("//Sources/App")
    test_action = xcode_schemes.test_action(["//Tests/FooTests"])

    actual = xcode_schemes.scheme(
        name = name,
        build_action = build_action,
        launch_action = launch_action,
        profile_action = profile_action,
        test_action = test_action,
    )
    expected = struct(
        name = "__Foo_Foo",
        build_action = build_action,
        launch_action = launch_action,
        profile_action = profile_action,
        test_action = test_action,
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

scheme_test = unittest.make(_scheme_test)

def _build_target_test(ctx):
    env = unittest.begin(ctx)

    actual = xcode_schemes.build_target("//Sources/Foo")
    expected = struct(
        label = bazel_labels.normalize_string("//Sources/Foo"),
        build_for = xcode_schemes.BUILD_FOR_ALL_ENABLED,
    )
    asserts.equals(env, expected, actual, "no build_for")

    actual = xcode_schemes.build_target(
        "//Sources/Foo",
        xcode_schemes.build_for(),
    )
    expected = struct(
        label = bazel_labels.normalize_string("//Sources/Foo"),
        build_for = xcode_schemes.build_for(),
    )
    asserts.equals(env, expected, actual, "with build_for")

    return unittest.end(env)

build_target_test = unittest.make(_build_target_test)

def _build_for_test(ctx):
    env = unittest.begin(ctx)

    actual = xcode_schemes.build_for()
    expected = struct(
        running = xcode_schemes.build_for_values.UNSPECIFIED,
        testing = xcode_schemes.build_for_values.UNSPECIFIED,
        profiling = xcode_schemes.build_for_values.UNSPECIFIED,
        archiving = xcode_schemes.build_for_values.UNSPECIFIED,
        analyzing = xcode_schemes.build_for_values.UNSPECIFIED,
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
        running = xcode_schemes.build_for_values.ENABLED,
        testing = xcode_schemes.build_for_values.ENABLED,
        profiling = xcode_schemes.build_for_values.ENABLED,
        archiving = xcode_schemes.build_for_values.ENABLED,
        analyzing = xcode_schemes.build_for_values.ENABLED,
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
        running = xcode_schemes.build_for_values.DISABLED,
        testing = xcode_schemes.build_for_values.ENABLED,
        profiling = xcode_schemes.build_for_values.DISABLED,
        archiving = xcode_schemes.build_for_values.ENABLED,
        analyzing = xcode_schemes.build_for_values.DISABLED,
    )
    asserts.equals(env, expected, actual, "mix it up")

    return unittest.end(env)

build_for_test = unittest.make(_build_for_test)

def _build_action_test(ctx):
    env = unittest.begin(ctx)

    targets = [
        "//Sources/Bar",
        xcode_schemes.build_target("//Sources/Foo"),
    ]
    actual = xcode_schemes.build_action(targets)

    expected = struct(
        targets = [
            xcode_schemes.build_target(bazel_labels.normalize_string("//Sources/Bar")),
            xcode_schemes.build_target(bazel_labels.normalize_string("//Sources/Foo")),
        ],
        pre_actions = [],
        post_actions = [],
    )
    asserts.equals(env, expected, actual)

    return unittest.end(env)

build_action_test = unittest.make(_build_action_test)

def _test_action_test(ctx):
    env = unittest.begin(ctx)

    targets = ["//Tests/FooTests"]

    actual = xcode_schemes.test_action(targets)
    expected = struct(
        build_configuration = None,
        targets = [bazel_labels.normalize_string(t) for t in targets],
        args = None,
        diagnostics = None,
        env = None,
        expand_variables_based_on = None,
        pre_actions = [],
        post_actions = [],
    )
    asserts.equals(env, expected, actual, "no custom values")

    args = ["--hello"]
    custom_env = {"CUSTOM_ENV_VAR": "goodbye"}
    actual = xcode_schemes.test_action(targets, args = args, env = custom_env)
    expected = struct(
        build_configuration = None,
        targets = [bazel_labels.normalize_string(t) for t in targets],
        args = args,
        diagnostics = None,
        env = custom_env,
        expand_variables_based_on = None,
        pre_actions = [],
        post_actions = [],
    )
    asserts.equals(env, expected, actual, "with custom values")

    actual = xcode_schemes.test_action(
        targets,
        args = [],
        env = {},
        expand_variables_based_on = "None",
    )
    expected = struct(
        build_configuration = None,
        targets = [bazel_labels.normalize_string(t) for t in targets],
        args = [],
        diagnostics = None,
        env = {},
        expand_variables_based_on = "none",
        pre_actions = [],
        post_actions = [],
    )
    asserts.equals(
        env,
        expected,
        actual,
        "expand_variables_based_on set to 'none'",
    )

    actual = xcode_schemes.test_action(
        targets,
        expand_variables_based_on = targets[0],
    )
    expected = struct(
        build_configuration = None,
        targets = [bazel_labels.normalize_string(t) for t in targets],
        args = None,
        diagnostics = None,
        env = None,
        expand_variables_based_on = bazel_labels.normalize_string(targets[0]),
        pre_actions = [],
        post_actions = [],
    )
    asserts.equals(
        env,
        expected,
        actual,
        "expand_variables_based_on set to test target",
    )

    return unittest.end(env)

test_action_test = unittest.make(_test_action_test)

def _launch_action_test(ctx):
    test_env = unittest.begin(ctx)

    target = "//Sources/App"
    args = ["my arg"]
    env = {"RELEASE_KRAKEN": "true"}

    actual = xcode_schemes.launch_action(
        target = target,
        args = args,
        env = env,
    )
    expected = struct(
        build_configuration = None,
        target = bazel_labels.normalize_string(target),
        args = args,
        diagnostics = None,
        env = env,
        working_directory = None,
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
