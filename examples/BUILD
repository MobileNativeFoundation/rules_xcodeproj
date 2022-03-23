load(
    "@cgrindel_rules_bazel_integration_test//bazel_integration_test:defs.bzl",
    "bazel_integration_test",
    "integration_test_utils",
)
load("//:bazel_versions.bzl", "CURRENT_BAZEL_VERSION")

# GH174: Enable integration tests for other (i.e., not the current) Bazel
# versions.

# config_setting(
#     name = "cache",
#     flag_values = {
#         "//config:integration_test_config": "cache",
#     },
# )

# config_setting(
#     name = "workflows",
#     flag_values = {
#         "//config:integration_test_config": "workflows",
#     },
# )

# genrule(
#     name = "chuck_debug",
#     srcs = [
#         "//config:integration_test_config",
#     ],
#     outs = ["chuck_debug.txt"],
#     cmd = """\
# cat $(location //config:integration_test_config) > $@
# """,
# )

sh_binary(
    name = "ios_app_test_runner",
    testonly = True,
    srcs = ["ios_app_test_runner.sh"],
    data = [
        "//config:integration_test_config",
    ],
    # args = select({
    #     ":cache": [
    #         "--config",
    #         "cache",
    #     ],
    #     ":workflows": [
    #         "--config",
    #         "workflows",
    #     ],
    #     "//conditions:default": [],
    # }),
    deps = [
        "@cgrindel_bazel_starlib//shlib/lib:assertions",
    ],
)

# config_setting(
#     name = "no_config",
#     flag_values = {
#         "//config:integration_test_config": "",
#     },
# )

# default_test_runner(
#     name = "ios_app_test_runner",
#     # bazel_cmds = [
#     #     "info",
#     #     "build //...",
#     #     # Make sure that whatever is checked in matches
#     #     "test //test/...",
#     #     # Run update fixtures and make sure all is still well
#     #     "run //test/fixtures:update",
#     #     "test //test/...",
#     #     # Make sure that xcodeproj executes successfully
#     #     "run //:xcodeproj",
#     # ],
#     bazel_cmds = select({
#         ":cache": [
#             "info",
#             "build --config=cache //...",
#             # Make sure that whatever is checked in matches
#             "test --config=cache //test/...",
#             # Run update fixtures and make sure all is still well
#             "run --config=cache //test/fixtures:update",
#             "test --config=cache //test/...",
#             # Make sure that xcodeproj executes successfully
#             "run --config=cache //:xcodeproj",
#         ],
#         ":workflows": [
#             "info",
#             "build --config=workflows //...",
#             # Make sure that whatever is checked in matches
#             "test --config=workflows //test/...",
#             # Run update fixtures and make sure all is still well
#             "run --config=workflows //test/fixtures:update",
#             "test --config=workflows //test/...",
#             # Make sure that xcodeproj executes successfully
#             "run --config=workflows //:xcodeproj",
#         ],
#         "//conditions:default": [
#             "info",
#             "build //...",
#             # Make sure that whatever is checked in matches
#             "test //test/...",
#             # Run update fixtures and make sure all is still well
#             "run //test/fixtures:update",
#             "test //test/...",
#             # Make sure that xcodeproj executes successfully
#             "run //:xcodeproj",
#         ],
#     }),
# )

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
