load("//xcodeproj:defs.bzl", "xcode_schemes", "xcodeproj")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:collections.bzl", "flatten", "uniq")

_TOOLS = {
    "files_and_groups": "//tools/generators/files_and_groups",
    "pbxproj_prefix": "//tools/generators/pbxproj_prefix",
    "pbxproject_targets": "//tools/generators/pbxproject_targets",
    "swiftc_stub": "//tools/swiftc_stub:swiftc",
}

_TESTS = {
    "files_and_groups": [
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/files_and_groups:files_and_groups_tests",
    ],
    "pbxproj_prefix": [
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/pbxproj_prefix:pbxproj_prefix_tests",
    ],
    "pbxproject_targets": [
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/pbxproject_targets:pbxproject_targets_tests",
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
        name = "pbxproject_targets",
        launch_action = xcode_schemes.launch_action(
            _TOOLS["pbxproject_targets"],
            args = [
                # targetsOutputPath
                "/tmp/pbxproj_partials/pbxproject_targets",
                # targetAttributesOutputPath
                "/tmp/pbxproj_partials/pbxproject_target_attributes",
                # targetDependenciesOutputPath
                "/tmp/pbxproj_partials/pbxtargetdependencies",
                # minimumXcodeVersion
                "14.0",
                # targetAndTestHosts
                "--target-and-test-hosts",
                "'//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3'",
                "'//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3'",
                # consolidationMapOutputPaths
                "--consolidation-map-output-paths",
                "/tmp/pbxproj_partials/consolidation_maps/0",
                "/tmp/pbxproj_partials/consolidation_maps/1",
                # labelCounts
                "--label-counts",
                "2",
                "1",
                # labels
                "--labels",
                "//tools/generators/legacy:generator",
                "//tools/generators/legacy/test:tests.__internal__.__test_bundle",
                "//tools/generators/legacy:generator.library",
                # targetCounts
                "--target-counts",
                "1",
                "1",
                "1",
                # targets
                "--targets",
                "'//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3'",
                "'//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3'",
                "'//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1'",
                # xcodeConfigurationCounts
                "--xcode-configuration-counts",
                "2",
                "1",
                "1",
                # xcodeConfigurations
                "--xcode-configurations",
                "Debug",
                "Release",
                "Release",
                "Debug",
                # productTypes
                "--product-types",
                "com.apple.product-type.tool",
                "com.apple.product-type.bundle.unit-test",
                "com.apple.product-type.library.static",
                # productPaths
                "--product-paths",
                "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/generator",
                "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest",
                "bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin/tools/generators/legacy/libgenerator.library.a",
                # platforms
                "--platforms",
                "macosx",
                "macosx",
                "macosx",
                # osVersions
                "--os-versions",
                "12.0",
                "12.0",
                "12.0",
                # archs
                "--archs",
                "x86_64",
                "x86_64",
                "x86_64",
                # dependencyCounts
                "--dependency-counts",
                "1",
                "1",
                "0",
                # dependencies
                "--dependencies",
                "'//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1'",
                "'//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1'",
            ],
            build_configuration = "Release",
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
        test_action = xcode_schemes.test_action(
            _TESTS["pbxproject_targets"],
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
        "//tools/generators/pbxproject_targets": [
            "//tools/generators/pbxproject_targets:README.md",
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
