load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_command_line_application",
    "macos_unit_test",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("//xcodeproj:defs.bzl", "xcodeproj", "xcode_schemes")

# "repro" command-line app

swift_library(
    name = "repro.library",
    srcs = glob(["src/**/*.swift"]),
    module_name = "repro",
    tags = ["manual"],
    deps = [
        "@com_github_apple_swift_collections//:OrderedCollections",
        "@com_github_kylef_pathkit//:PathKit",
        "@com_github_michaeleisel_zippyjson//:ZippyJSON",
        "@com_github_tuist_xcodeproj//:XcodeProj",
    ],
)

macos_command_line_application(
    name = "repro",
    minimum_os_version = "12.0",
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = [":repro.library"],
)

# "repro_test" unit test

swift_library(
    name = "repro_tests.library",
    testonly = True,
    srcs = glob(["tests/**/*.swift"]),
    module_name = "repro_tests",
    tags = ["manual"],
    deps = [
        ":repro.library",
    ],
)

macos_unit_test(
    name = "repro_tests",
    minimum_os_version = "12.0",
    tags = ["manual"],
    deps = [
        ":repro_tests.library",
    ],
)

# Xcode project

xcodeproj(
    name = "xcodeproj",
    build_mode = "xcode",
    config = "repro_rules_xcodeproj",
    project_name = "repro",
    schemes = [
        xcode_schemes.scheme(
            name = "repro",
            launch_action = xcode_schemes.launch_action(
                ":repro",
                args = [
                    "/tmp/spec.json",
                ],
                working_directory = "$(BUILD_WORKSPACE_DIRECTORY)",
            ),
            test_action = xcode_schemes.test_action(
                [":repro_tests"],
                env = {"SPEC_PATH": "/tmp/spec.json"},
            ),
        ),
    ],
    tags = ["manual"],
    top_level_targets = [
        ":repro",
        ":repro_tests",
    ],
)
