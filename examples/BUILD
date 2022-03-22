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
    workspace_files = glob(
        ["ios_app/**/*"],
        exclude = [
            "ios_app/bazel-*",
            # Ignore any Xcode projects that may have been manually generated
            "ios_app/*.xcodeproj/**",
        ],
    ) + [
        "//:local_repository_files",
    ],
    workspace_path = "ios_app",
)

test_suite(
    name = "all_integration_tests",
    tags = integration_test_utils.DEFAULT_INTEGRATION_TEST_TAGS,
    tests = [
        "ios_app_test",
    ],
    visibility = ["//:__subpackages__"],
)
