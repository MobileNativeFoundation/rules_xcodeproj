load(
    "@contrib_rules_bazel_integration_test//bazel_integration_test:defs.bzl",
    "bazel_integration_test",
    "integration_test_utils",
)
load("//:bazel_versions.bzl", "CURRENT_BAZEL_VERSION")

# GH174: Enable integration tests for other (i.e., not the current) Bazel
# versions.

sh_binary(
    name = "integration_test_runner",
    testonly = True,
    srcs = ["integration_test_runner.sh"],
    data = [
        "//config:integration_test_config",
    ],
    deps = [
        "@cgrindel_bazel_starlib//shlib/lib:assertions",
    ],
)

bazel_integration_test(
    name = "ios_app_test",
    additional_env_inherit = ["DEVELOPER_DIR"],
    bazel_version = CURRENT_BAZEL_VERSION,
    test_runner = ":integration_test_runner",
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
