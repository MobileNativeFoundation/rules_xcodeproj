load("//xcodeproj:defs.bzl", "xcode_schemes", "xcodeproj")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:collections.bzl", "flatten", "uniq")

_TOOLS = {
    "files_and_groups": "//tools/generators/files_and_groups",
    "GeneratorCommonMacros": "//tools/generators/lib/GeneratorCommon/Macros:GeneratorCommonMacros",
    "pbxproj_prefix": "//tools/generators/pbxproj_prefix",
    "swiftc_stub": "//tools/swiftc_stub:swiftc",
}

_TESTS = {
    "files_and_groups": [
        "//tools/generators/lib/GeneratorCommon/Macros:GeneratorCommonMacrosTests",
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/files_and_groups:files_and_groups_tests",
    ],
    "GeneratorCommonMacros": [
        "//tools/generators/lib/GeneratorCommon/Macros:GeneratorCommonMacrosTests",
    ],
    "pbxproj_prefix": [
        "//tools/generators/lib/GeneratorCommon/Macros:GeneratorCommonMacrosTests",
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/pbxproj_prefix:pbxproj_prefix_tests",
    ],
}

_SCHEME_DIAGNOSTICS = xcode_schemes.diagnostics(
    sanitizers = xcode_schemes.sanitizers(
        address = True,
    ),
)

_SCHEMES = [
    xcode_schemes.scheme(
        name = "files_and_groups",
        launch_action = xcode_schemes.launch_action(
            _TOOLS["files_and_groups"],
            args = [
                # knownRegionsOutputPath
                "/tmp/pbxproj_partials/known_regions",
                # filesAndGroupsOutputPath
                "/tmp/pbxproj_partials/files_and_groups",
                # resolvedRepositoriesOutputPath
                "/tmp/pbxproj_partials/resolved_repositories",
                # workspace
                "/tmp/workspace",
                # executionRootFile
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_execution_root_file",
                # selectedModelVersionsFile
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/selected_model_versions_file",
                # developmentRegion
                "en",
                # useBaseInternationalization
                "--use-base-internationalization",
                # filePaths
                "--file-paths",
                "a/project/file",
                "bazel-out/generated/file",
                "external/repository/file",
                # folderPaths
                "--folder-paths",
                "a/project/structure/resource/folder",
            ],
            build_configuration = "Release",
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
        test_action = xcode_schemes.test_action(
            _TESTS["files_and_groups"],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
    ),
    xcode_schemes.scheme(
        name = "GeneratorCommonMacros",
        launch_action = xcode_schemes.launch_action(
            _TOOLS["GeneratorCommonMacros"],
            build_configuration = "Release",
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
        test_action = xcode_schemes.test_action(
            _TESTS["GeneratorCommonMacros"],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
    ),
    xcode_schemes.scheme(
        name = "pbxproj_prefix",
        launch_action = xcode_schemes.launch_action(
            _TOOLS["pbxproj_prefix"],
            args = [
                # outputPath
                "/tmp/pbxproj_partials/pbxproj_prefix",
                # workspace
                "/tmp/workspace",
                # executionRootFile
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_execution_root_file",
                # targetIdsFile
                "bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_target_ids",
                # indexImport
                "bazel-out/darwin_arm64-opt-exec-2B5CBBC6/bin/external/_main~non_module_deps~rules_xcodeproj_index_import/index-import",
                # resolvedRepositoriesFile
                "bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/xcodeproj/xcodeproj_pbxproj_partials/resolved_repositories",
                # buildMode
                "bazel",
                # minimumXcodeVersion
                "14.0",
                # developmentRegion
                "enGB",
                # organizationName
                "--organization-name",
                "MobileNativeFoundation",
                # platforms
                "--platforms",
                "macosx",
                "iphonesimulator",
                # xcodeConfigurations
                "--xcode-configurations",
                "Debug",
                "Release",
                # defaultXcodeConfiguration
                "--default-xcode-configuration",
                "Release",
                # preBuildScript
                # postBuildScript
            ],
            build_configuration = "Release",
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
        test_action = xcode_schemes.test_action(
            _TESTS["pbxproj_prefix"],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
    ),
    xcode_schemes.scheme(
        name = "swiftc_stub",
        build_action = xcode_schemes.build_action(
            targets = [
                xcode_schemes.build_target(
                    _TOOLS["swiftc_stub"],
                ),
            ],
        ),
        launch_action = xcode_schemes.launch_action(
            _TOOLS["swiftc_stub"],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
    ),
]

_XCODE_CONFIGURATIONS = {
    "Debug": {
        "//command_line_option:apple_generate_dsym": False,
        "//command_line_option:compilation_mode": "dbg",
        "//command_line_option:features": [],
    },
    "Release": {
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
}

xcodeproj(
    name = "xcodeproj",
    associated_extra_files = {
        "//tools/generators/files_and_groups": [
            "//tools/generators/files_and_groups:README.md",
        ],
        "//tools/generators/pbxproj_prefix": [
            "//tools/generators/pbxproj_prefix:README.md",
        ],
    },
    extra_files = [
        "//tools/generators:README.md",
    ],
    project_name = "tools",
    scheme_autogeneration_mode = "none",
    schemes = _SCHEMES,
    top_level_targets = _TOOLS.values() + uniq(flatten(_TESTS.values())),
    xcode_configurations = _XCODE_CONFIGURATIONS,
)

# Release

sh_binary(
    name = "set_release_archive_override",
    srcs = ["set_release_archive_override.sh"],
    tags = ["manual"],
)

filegroup(
    name = "release_files",
    srcs = [
        "//" + package_name() + "/extensionpointidentifiers_parser:release_files",
        "//" + package_name() + "/generators:release_files",
        "//" + package_name() + "/params_processors:release_files",
        "//" + package_name() + "/swiftc_stub:release_files",
        "//" + package_name() + "/xccurrentversions_parser:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)
