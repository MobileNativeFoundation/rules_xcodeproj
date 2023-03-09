"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load("//xcodeproj:defs.bzl", "xcode_schemes")

UNFOCUSED_TARGETS = [
    "@com_github_tadija_aexml//:AEXML",
]

_APP_TARGET = "//tools/generator"
_TEST_TARGET = "//tools/generator/test:tests"
_TOOL_TARGET = "//tools/swiftc_stub:swiftc"

TOP_LEVEL_TARGETS = [_APP_TARGET, _TEST_TARGET, _TOOL_TARGET]

XCODE_CONFIGURATIONS = {
    "Debug": {
        "//command_line_option:compilation_mode": "dbg",
    },
    "Profile": {
        "//command_line_option:compilation_mode": "opt",
    },
}

SCHEME_AUTOGENERATION_MODE = "none"

# tl;dr The `tools/generator` custom Xcode schemes are wrapped in a function
# because they are shared with `//tools/generator:xcodeproj` and
# `//test/fixtures/generator:xcodeproj`.
#
# The Xcode schemes for `tools/generator` are loaded from a function because
# several of the `xcode_schemes` functions must be called on a BUILD file
# thread as they resolve and normalize Bazel labels. These functions use
# `bazel_labels.parse` which, in turn, use `workspace_name_resolvers`
# functions. It is the `workspace_name_resolvers` functions that must be called
# on a BUILD file thread.
#
# Most `rules_xcodeproj` clients should not need to wrap their custom scheme
# declarations in a function. They should be declared in a BUILD file alongside
# or inline with their `xcodeproj` target. Wrapping the declarations in a
# function is only necessary when sharing a set of custom schemes as is done
# with the fixture tests in this repository.

def get_xcode_schemes():
    return [
        xcode_schemes.scheme(
            name = "generator",
            # The build_action in this example is not necessary for the scheme
            # to work. It is here to test that customized build_for settings
            # propagate properly.
            build_action = xcode_schemes.build_action(
                targets = [
                    xcode_schemes.build_target(
                        _APP_TARGET,
                        xcode_schemes.build_for(archiving = True),
                    ),
                ],
                pre_actions = [
                    xcode_schemes.pre_post_action(
                        script = "echo 'Building target: generator'",
                        name = "Example: Start build time tracking...",
                        expand_variables_based_on = _APP_TARGET,
                    ),
                ],
                post_actions = [
                    xcode_schemes.pre_post_action(
                        script = "echo 'Completed Building target: generator'",
                        name = "Example: Stop build time tracking...",
                        expand_variables_based_on = _APP_TARGET,
                    ),
                ],
            ),
            launch_action = xcode_schemes.launch_action(
                _APP_TARGET,
                args = [
                    "bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-dbg/bin/tools/generator/xcodeproj.generator_root_dirs",
                    "bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-dbg/bin/tools/generator/xcodeproj.generator_xccurrentversions",
                    "bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-dbg/bin/tools/generator/xcodeproj.generator_extensionpointidentifiers",
                    "/tmp/out.xcodeproj",
                    "/tmp/out.final.xcodeproj",
                    "bazel",
                    "0",
                    "/tmp/specs/xcodeproj.generator-project_spec.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.0.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.1.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.2.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.3.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.4.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.5.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.6.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.7.json",
                ],
                # This is not necessary for the generator. It is here to help
                # verify that custom environment variables are passed along.
                env = {"CUSTOM_ENV_VAR": "hello"},
                diagnostics = xcode_schemes.diagnostics(
                    sanitizers = xcode_schemes.sanitizers(
                        address = True,
                    ),
                ),
                working_directory = "$(BUILD_WORKSPACE_DIRECTORY)",
            ),
            profile_action = xcode_schemes.profile_action(
                _APP_TARGET,
                args = [
                    "bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-opt/bin/tools/generator/xcodeproj.generator_root_dirs",
                    "bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-opt/bin/tools/generator/xcodeproj.generator_xccurrentversions",
                    "bazel-output-base/rules_xcodeproj/build_output_base/execroot/rules_xcodeproj/bazel-out/darwin_arm64-opt/bin/tools/generator/xcodeproj.generator_extensionpointidentifiers",
                    "/tmp/out.xcodeproj",
                    "/tmp/out.final.xcodeproj",
                    "bazel",
                    "0",
                    "/tmp/specs/xcodeproj.generator-project_spec.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.0.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.1.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.2.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.3.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.4.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.5.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.6.json",
                    "/tmp/specs/xcodeproj.generator-targets_spec.7.json",
                ],
                build_configuration = "Profile",
                working_directory = "$(BUILD_WORKSPACE_DIRECTORY)",
            ),
            test_action = xcode_schemes.test_action(
                [_TEST_TARGET],
                # This is not necessary for the generator tests. It is here to help
                # verify that custom environment variables are passed along.
                env = {"CUSTOM_ENV_VAR": "goodbye"},
                diagnostics = xcode_schemes.diagnostics(
                    sanitizers = xcode_schemes.sanitizers(
                        address = True,
                    ),
                ),
            ),
        ),
        xcode_schemes.scheme(
            name = "swiftc",
            build_action = xcode_schemes.build_action(
                targets = [
                    xcode_schemes.build_target(
                        _TOOL_TARGET,
                    ),
                ],
            ),
            launch_action = xcode_schemes.launch_action(
                _TOOL_TARGET,
                diagnostics = xcode_schemes.diagnostics(
                    sanitizers = xcode_schemes.sanitizers(
                        address = True,
                    ),
                ),
            ),
        ),
    ]
