load("//xcodeproj:defs.bzl", "xcode_schemes", "xcodeproj")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:collections.bzl", "flatten", "uniq")

_TOOLS = {
    "files_and_groups": "//tools/generators/files_and_groups",
    "import_indexstores": "//tools/import_indexstores",
    "pbxproj_prefix": "//tools/generators/pbxproj_prefix",
    "pbxtargetdependencies": "//tools/generators/pbxtargetdependencies",
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
    "pbxtargetdependencies": [
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/pbxtargetdependencies:pbxtargetdependencies_tests",
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
                # installPath
                "some/project.xcodeproj",
                # executionRootFile
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_execution_root_file",
                # selectedModelVersionsFile
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/selected_model_versions_file",
                # filePathsFile
                "/tmp/pbxproj_partials/file_paths_file",
                # folderPathsFile
                "/tmp/pbxproj_partials/folder_paths_file",
                # developmentRegion
                "en",
                # useBaseInternationalization
                "--use-base-internationalization",
                # buildFileSubIdentifiersFiles
                "--build-file-sub-identifiers-files",
                "/tmp/pbxproj_partials/buildfile_subidentifiers/0",
                "/tmp/pbxproj_partials/buildfile_subidentifiers/1",
            ],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
        profile_action = xcode_schemes.profile_action(
            _TOOLS["files_and_groups"],
            build_configuration = "Release",
        ),
        test_action = xcode_schemes.test_action(
            _TESTS["files_and_groups"],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
    ),
    xcode_schemes.scheme(
        name = "import_indexstores",
        build_action = xcode_schemes.build_action(
            targets = [
                xcode_schemes.build_target(
                    _TOOLS["import_indexstores"],
                ),
            ],
        ),
        launch_action = xcode_schemes.launch_action(
            _TOOLS["import_indexstores"],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
        profile_action = xcode_schemes.profile_action(
            _TOOLS["import_indexstores"],
            build_configuration = "Release",
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
                # minimumXcodeVersion
                "14.0",
                # defaultXcodeConfiguration
                "Release",
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
                # preBuildScript
                # postBuildScript
            ],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
        profile_action = xcode_schemes.profile_action(
            _TOOLS["pbxproj_prefix"],
            build_configuration = "Release",
        ),
        test_action = xcode_schemes.test_action(
            _TESTS["pbxproj_prefix"],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
    ),
    xcode_schemes.scheme(
        name = "pbxtargetdependencies",
        launch_action = xcode_schemes.launch_action(
            _TOOLS["pbxtargetdependencies"],
            args = [
                # targetDependenciesOutputPath
                "/tmp/pbxproj_partials/pbxtargetdependencies",
                # targetsOutputPath
                "/tmp/pbxproj_partials/pbxtargetdependencies",
                # targetAttributesOutputPath
                "/tmp/pbxproj_partials/pbxproject_target_attributes",
                # consolidationMapsInputsFile
                "/tmp/pbxproj_partials/consolidation_maps_inputs_file",
                # minimumXcodeVersion
                "14.0",
                # targetNameMode
                "auto",
                # targetAndTestHosts
                "--target-and-test-hosts",
                "'//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3'",
                "'//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3'",
            ],
            diagnostics = _SCHEME_DIAGNOSTICS,
        ),
        profile_action = xcode_schemes.profile_action(
            _TOOLS["pbxtargetdependencies"],
            build_configuration = "Release",
        ),
        test_action = xcode_schemes.test_action(
            _TESTS["pbxtargetdependencies"],
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
        profile_action = xcode_schemes.profile_action(
            _TOOLS["swiftc_stub"],
            build_configuration = "Release",
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
        "//tools/generators/pbxtargetdependencies": [
            "//tools/generators/pbxtargetdependencies:README.md",
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

filegroup(
    name = "release_files",
    srcs = [
        "//" + package_name() + "/extension_point_identifiers_parser:release_files",
        "//" + package_name() + "/generators:release_files",
        "//" + package_name() + "/import_indexstores:release_files",
        "//" + package_name() + "/params_processors:release_files",
        "//" + package_name() + "/swiftc_stub:release_files",
        "//" + package_name() + "/xccurrentversions_parser:release_files",
    ],
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)
