"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load("//xcodeproj:defs.bzl", "xcode_schemes", "xcschemes")

UNFOCUSED_TARGETS = [
    "@com_github_tadija_aexml//:AEXML",
]

_APP_TARGET = "//tools/generators/legacy:generator"
_TEST_TARGET = "//tools/generators/legacy/test:tests"
_TOOL_TARGET = "//tools/swiftc_stub:swiftc"

TOP_LEVEL_TARGETS = [_APP_TARGET, _TEST_TARGET, _TOOL_TARGET]

XCODE_CONFIGURATIONS = {
    "Debug": {
        "//command_line_option:apple_generate_dsym": False,
        "//command_line_option:compilation_mode": "dbg",
        "//command_line_option:features": [],
    },
    # Profile and Release are identical to exercise identical configuration
    # handling (which includes code paths in both Starlark and the generator)
    "Profile": {
        "//command_line_option:apple_generate_dsym": True,
        "//command_line_option:compilation_mode": "opt",
        # Until we have a solution for Instruments.app handling relative paths,
        # we need the debug info to include absolute source paths
        "//command_line_option:features": [
            "-swift.debug_prefix_map",
            "-swift.file_prefix_map",
            "-swift.index_while_building",
        ],
    },
    "Release": {
        "//command_line_option:apple_generate_dsym": True,
        "//command_line_option:compilation_mode": "opt",
        "//command_line_option:features": [
            "-swift.debug_prefix_map",
            "-swift.file_prefix_map",
            "-swift.index_while_building",
        ],
    },
}

SCHEME_AUTOGENERATION_MODE = "none"

# tl;dr The `tools/generators/legacy:generator` custom Xcode schemes are wrapped in a
# function because they are shared with `//tools/generators/legacy:xcodeproj`
# and `//test/fixtures/generator:xcodeproj`.
#
# The Xcode schemes for `tools/generators/legacy` are loaded from a function
# because several of the `xcode_schemes` functions must be called on a BUILD
# file thread as they resolve and normalize Bazel labels. These functions use
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
            launch_action = xcode_schemes.launch_action(
                _APP_TARGET,
                args = [
                    "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/legacy/xcodeproj/xcodeproj_execution_root_file",
                    "/tmp/workspace",
                    "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/legacy/xcodeproj/xcodeproj_xccurrentversions",
                    "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/legacy/xcodeproj/xcodeproj_extensionpointidentifiers",
                    "/tmp/out.xcodeproj",
                    "/tmp/out.final.xcodeproj",
                    "bazel",
                    "0",
                    "0",
                    "/tmp/specs/xcodeproj-project_spec.json",
                    "/tmp/specs/custom_xcode_schemes.json",
                    "/tmp/specs/xcodeproj-targets_spec.0.json",
                    "/tmp/specs/xcodeproj-targets_spec.1.json",
                    "/tmp/specs/xcodeproj-targets_spec.2.json",
                    "/tmp/specs/xcodeproj-targets_spec.3.json",
                    "/tmp/specs/xcodeproj-targets_spec.4.json",
                    "/tmp/specs/xcodeproj-targets_spec.5.json",
                    "/tmp/specs/xcodeproj-targets_spec.6.json",
                    "/tmp/specs/xcodeproj-targets_spec.7.json",
                ],
                build_configuration = "Release",
                diagnostics = xcode_schemes.diagnostics(
                    sanitizers = xcode_schemes.sanitizers(
                        address = True,
                    ),
                ),
                working_directory = "/tmp",
            ),
            profile_action = xcode_schemes.profile_action(
                _APP_TARGET,
                args = [
                    "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/legacy/xcodeproj/xcodeproj_execution_root_file",
                    "/tmp/workspace",
                    "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/legacy/xcodeproj/xcodeproj_xccurrentversions",
                    "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/legacy/xcodeproj/xcodeproj_extensionpointidentifiers",
                    "/tmp/out.xcodeproj",
                    "/tmp/out.final.xcodeproj",
                    "bazel",
                    "0",
                    "0",
                    "/tmp/specs/xcodeproj-project_spec.json",
                    "/tmp/specs/custom_xcode_schemes.json",
                    "/tmp/specs/xcodeproj-targets_spec.0.json",
                    "/tmp/specs/xcodeproj-targets_spec.1.json",
                    "/tmp/specs/xcodeproj-targets_spec.2.json",
                    "/tmp/specs/xcodeproj-targets_spec.3.json",
                    "/tmp/specs/xcodeproj-targets_spec.4.json",
                    "/tmp/specs/xcodeproj-targets_spec.5.json",
                    "/tmp/specs/xcodeproj-targets_spec.6.json",
                    "/tmp/specs/xcodeproj-targets_spec.7.json",
                ],
                build_configuration = "Profile",
                working_directory = "/tmp",
            ),
            test_action = xcode_schemes.test_action(
                [_TEST_TARGET],
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

XCSCHEMES = [
    xcschemes.scheme(
        name = "generator",
        run = xcschemes.run(
            launch_target = xcschemes.launch_target(
                ":generator",
                working_directory = "/tmp",
            ),
            xcode_configuration = "Release",
            args = [
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/legacy/xcodeproj/xcodeproj_execution_root_file",
                "/tmp/workspace",
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/legacy/xcodeproj/xcodeproj_xccurrentversions",
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/legacy/xcodeproj/xcodeproj_extensionpointidentifiers",
                "/tmp/out.xcodeproj",
                "/tmp/out.final.xcodeproj",
                "bazel",
                "0",
                "0",
                "/tmp/specs/xcodeproj-project_spec.json",
                "/tmp/specs/custom_xcode_schemes.json",
                "/tmp/specs/xcodeproj-targets_spec.0.json",
                "/tmp/specs/xcodeproj-targets_spec.1.json",
                "/tmp/specs/xcodeproj-targets_spec.2.json",
                "/tmp/specs/xcodeproj-targets_spec.3.json",
                "/tmp/specs/xcodeproj-targets_spec.4.json",
                "/tmp/specs/xcodeproj-targets_spec.5.json",
                "/tmp/specs/xcodeproj-targets_spec.6.json",
                "/tmp/specs/xcodeproj-targets_spec.7.json",
            ],
            diagnostics = xcschemes.diagnostics(
                address_sanitizer = True,
            ),
        ),
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                ":generator",
                working_directory = "/tmp",
            ),
            xcode_configuration = "Profile",
        ),
        test = xcschemes.test(
            test_targets = [
                "//tools/generators/legacy/test:tests",
            ],
            diagnostics = xcschemes.diagnostics(
                address_sanitizer = True,
            ),
        ),
    ),
    xcschemes.scheme(
        name = "swiftc",
        run = xcschemes.run(
            launch_target = xcschemes.launch_target(
                "//tools/swiftc_stub:swiftc",
            ),
            diagnostics = xcschemes.diagnostics(
                address_sanitizer = True,
            ),
        ),
    ),
]
