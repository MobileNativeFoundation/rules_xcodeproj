load(
    "@cgrindel_rules_bazel_integration_test//bazel_integration_test:defs.bzl",
    "bazel_integration_test",
    "default_test_runner",
    "integration_test_utils",
)
load("//:bazel_versions.bzl", "CURRENT_BAZEL_VERSION")

# GH174: Enable integration tests for other (i.e., not the current) Bazel
# versions.

default_test_runner(
    name = "ios_app_test_runner",
    bazel_cmds = [
        "info",
        "build //...",
        # Make sure that whatever is checked in matches
        "test //test/...",
        # Run update fixtures and make sure all is still well
        "run //test/fixtures:update",
        "test //test/...",
        # Make sure that xcodeproj executes successfully
        "run //:xcodeproj",
    ],
)

bazel_integration_test(
    name = "ios_app_test",
    additional_env_inherit = ["DEVELOPER_DIR"],
    bazel_version = CURRENT_BAZEL_VERSION,
    test_runner = ":ios_app_test_runner",
    workspace_files = integration_test_utils.glob_workspace_files("ios_app") + [
        "//:local_repository_files",
    ],
    workspace_path = "ios_app",
)

# By default, the integration test targets are tagged as `manual`. This
# prevents the targets from being found from most target expansion (e.g.
# `//...`, `:all`). To easily execute a group of integration tests, you may
# want to define a test suite which includes the desired test targets.
test_suite(
    name = "all_integration_tests",
    # If you don't apply the test tags to the test suite, the test suite will
    # be found when `bazel test //...` is executed.
    tags = integration_test_utils.DEFAULT_INTEGRATION_TEST_TAGS,
    tests = [
        "ios_app_test",
    ],
    visibility = ["//:__subpackages__"],
)
