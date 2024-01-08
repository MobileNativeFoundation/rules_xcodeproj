load("//xcodeproj:defs.bzl", "xcodeproj", "xcschemes")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:collections.bzl", "flatten", "uniq")

_TOOLS = {
    "files_and_groups": "//tools/generators/files_and_groups",
    "import_indexstores": "//tools/import_indexstores",
    "pbxnativetargets": "//tools/generators/pbxnativetargets",
    "pbxproj_prefix": "//tools/generators/pbxproj_prefix",
    "pbxtargetdependencies": "//tools/generators/pbxtargetdependencies",
    "swift_debug_settings": "//tools/generators/swift_debug_settings",
    "swiftc_stub": "//tools/swiftc_stub:swiftc",
    "target_build_settings": "//tools/generators/target_build_settings",
    "xcschemes": "//tools/generators/xcschemes",
}

_TESTS = {
    "files_and_groups": [
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/files_and_groups:files_and_groups_tests",
    ],
    "pbxnativetargets": [
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/lib/XCScheme:XCSchemeTests",
        "//tools/generators/pbxnativetargets:pbxnativetargets_tests",
    ],
    "pbxproj_prefix": [
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/pbxproj_prefix:pbxproj_prefix_tests",
    ],
    "pbxtargetdependencies": [
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/pbxtargetdependencies:pbxtargetdependencies_tests",
    ],
    "swift_debug_settings": [
        "//tools/generators/swift_debug_settings:swift_debug_settings_tests",
    ],
    "target_build_settings": [
        "//tools/generators/target_build_settings:target_build_settings_tests",
    ],
    "xcschemes": [
        "//tools/generators/lib/PBXProj:PBXProjTests",
        "//tools/generators/lib/XCScheme:XCSchemeTests",
        "//tools/generators/xcschemes:xcschemes_tests",
    ],
}

_XCSCHEME_DIAGNOSTICS = xcschemes.diagnostics(
    address_sanitizer = True,
)

_XCSCHEMES = [
    xcschemes.scheme(
        name = "files_and_groups",
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                _TOOLS["files_and_groups"],
            ),
            xcode_configuration = "Release",
        ),
        run = xcschemes.run(
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
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            launch_target = xcschemes.launch_target(
                _TOOLS["files_and_groups"],
            ),
        ),
        test = xcschemes.test(
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            test_targets = _TESTS["files_and_groups"],
        ),
    ),
    xcschemes.scheme(
        name = "import_indexstores",
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                _TOOLS["import_indexstores"],
            ),
            xcode_configuration = "Release",
        ),
        run = xcschemes.run(
            build_targets = [
                _TOOLS["import_indexstores"],
            ],
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            launch_target = xcschemes.launch_target(
                _TOOLS["import_indexstores"],
            ),
        ),
    ),
    xcschemes.scheme(
        name = "pbxnativetargets",
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                _TOOLS["pbxnativetargets"],
            ),
            xcode_configuration = "Release",
        ),
        run = xcschemes.run(
            args = [
                # targetsOutputPath
                "/tmp/pbxproj_partials/pbxnativetargets/0",
                # buildFileSubIdentifiersOutputPath
                "/tmp/pbxproj_partials/buildfile_subidentifiers/0",
                # consolidationMap
                "/tmp/pbxproj_partials/consolidation_maps/0",
                # targetArgumentsFile
                "/tmp/pbxproj_partials/target_arguments_files/7",
                # topLevelTargetAttributesFile
                "/tmp/pbxproj_partials/top_level_target_attributes_files/7",
                # unitTestHostAttributesFile
                "/tmp/pbxproj_partials/unit_test_host_attributes_files/7",
                # defaultXcodeConfiguration
                "Debug",
            ],
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            launch_target = xcschemes.launch_target(
                _TOOLS["pbxnativetargets"],
            ),
        ),
        test = xcschemes.test(
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            test_targets = _TESTS["pbxnativetargets"],
        ),
    ),
    xcschemes.scheme(
        name = "pbxproj_prefix",
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                _TOOLS["pbxproj_prefix"],
            ),
            xcode_configuration = "Release",
        ),
        run = xcschemes.run(
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
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            launch_target = xcschemes.launch_target(
                _TOOLS["pbxproj_prefix"],
            ),
        ),
        test = xcschemes.test(
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            test_targets = _TESTS["pbxproj_prefix"],
        ),
    ),
    xcschemes.scheme(
        name = "pbxtargetdependencies",
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                _TOOLS["pbxtargetdependencies"],
            ),
            xcode_configuration = "Release",
        ),
        run = xcschemes.run(
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
                "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
                "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
            ],
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            launch_target = xcschemes.launch_target(
                _TOOLS["pbxtargetdependencies"],
            ),
        ),
        test = xcschemes.test(
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            test_targets = _TESTS["pbxtargetdependencies"],
        ),
    ),
    xcschemes.scheme(
        name = "swift_debug_settings",
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                _TOOLS["swift_debug_settings"],
            ),
            xcode_configuration = "Release",
        ),
        run = xcschemes.run(
            args = [
                # colorize
                "0",
                # outputPath
                "/tmp/pbxproj_partials/Debug-target_build_settings.py",
                # keysAndFiles
            ],
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            launch_target = xcschemes.launch_target(
                _TOOLS["swift_debug_settings"],
            ),
        ),
        test = xcschemes.test(
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            test_targets = _TESTS["swift_debug_settings"],
        ),
    ),
    xcschemes.scheme(
        name = "swiftc_stub",
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                _TOOLS["swiftc_stub"],
            ),
            xcode_configuration = "Release",
        ),
        run = xcschemes.run(
            build_targets = [
                _TOOLS["swiftc_stub"],
            ],
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            launch_target = xcschemes.launch_target(
                _TOOLS["swiftc_stub"],
            ),
        ),
    ),
    xcschemes.scheme(
        name = "target_build_settings",
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                _TOOLS["target_build_settings"],
            ),
            xcode_configuration = "Release",
        ),
        run = xcschemes.run(
            args = [
                # colorize
                "0",
                # buildSettingsOutputPath
                "/tmp/pbxproj_partials/target_build_settings",
                # swiftDebugSettingsOutputPath
                "/tmp/pbxproj_partials/swift_debug_settings",
                # includeSelfSwiftDebugSettings
                "1",
                # transitiveSwiftDebugSettingPaths
                "2",
                "/tmp/pbxproj_partials/transitive_swift_debug_settings_0",
                "/tmp/pbxproj_partials/transitive_swift_debug_settings_1",
                # deviceFamily
                "4",
                # extensionSafe
                "0",
                # generatesDsyms
                "1",
                # infoPlist
                "bazel-out/generated/Info.plist",
                # entitlements
                "project/level/app.entitlements",
                # certificateName
                "",
                # provisioningProfileName
                "",
                # teamID
                "",
                # provisioningProfileIsXcodeManaged
                "0",
                # packageBinDir
                "bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib",
                # previewFrameworkPaths
                "",
                # previewsIncludePath
                "",
                # swiftArgs
                "-target",
                "arm64_32-apple-watchos7.0",
                "-sdk",
                "__BAZEL_XCODE_SDKROOT__",
                "-debug-prefix-map",
                "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
                "-file-prefix-map",
                "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
                "-emit-object",
                "-output-file-map",
                "bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/Lib.output_file_map.json",
                "-Xfrontend",
                "-no-clang-module-breadcrumbs",
                "-swift-version",
                "4.2",
                "-emit-module-path",
                "bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/Lib.swiftmodule",
                "-emit-objc-header-path",
                "bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/generated/Lib-Swift.h",
                "-enable-bare-slash-regex",
                "-DNDEBUG",
                "-O",
                "-whole-module-optimization",
                "-Xfrontend",
                "-no-serialize-debugging-options",
                "-g",
                "-Xwrapped-swift=-debug-prefix-pwd-is-dot",
                "-Xwrapped-swift=-file-prefix-pwd-is-dot",
                "-module-cache-path",
                "bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/_swift_module_cache",
                "-Fexternal/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k",
                "-Xcc",
                "-Fexternal/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k",
                "-Xcc",
                "-iquoteexternal/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift",
                "-Xcc",
                "-iquotebazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift",
                "-Xcc",
                "-iquote.",
                "-Xcc",
                "-iquotebazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin",
                "-Xcc",
                "-fmodule-map-file=external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap",
                "-Xfrontend",
                "-color-diagnostics",
                "-num-threads",
                "12",
                "-module-name",
                "Lib",
                "-Xwrapped-swift=-global-index-store-import-path=bazel-out/_global_index_store",
                "-index-store-path",
                "bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/Lib.indexstore",
                "-Xfrontend",
                "-disable-autolink-framework",
                "-Xfrontend",
                "CryptoSwift",
                "-Xfrontend",
                "-vfsoverlay",
                "-Xfrontend",
                "project/relative/overlay.yaml",
                "-Xcc",
                "-ivfsoverlay=external/overlay.yaml",
                "-vfsoverlay",
                "bazel-out/generated/overlay.yaml",
                "-Xfrontend",
                "-explicit-swift-module-map-file",
                "-Xfrontend",
                "bazel-out/generated/map.json",
                "-Xfrontend",
                "-load-plugin-executable",
                "-Xfrontend",
                "bazel-out/generated/macro",
                "-parse-as-library",
                "-application-extension",
                "-static",
                "-Xcc",
                "-Os",
                "-Xcc",
                "-DNDEBUG=1",
                "-Xcc",
                "-Wno-unused-variable",
                "-Xcc",
                "-Winit-self",
                "-Xcc",
                "-Wno-extra",
                "Lib/Resources.swift",
                "bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/Lib.swift",
                # cParamsOutputPath
                "---",
                "/tmp/pbxproj_partials/c.compile.params",
                # cArgs
                "-Os",
                "-ivfsoverlay=external/overlay.yaml",
                "--config",
                "some.cfg",
                # cxxParamsOutputPath
                "---",
                "/tmp/pbxproj_partials/cxx.compile.params",
                # cxxArgs
                "-Os",
                "-D_FORTIFY_SOURCE=2",
                "-ivfsoverlay",
                "bazel-out/generated/overlay.yaml",
            ],
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            launch_target = xcschemes.launch_target(
                _TOOLS["target_build_settings"],
            ),
        ),
        test = xcschemes.test(
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            test_targets = _TESTS["target_build_settings"],
        ),
    ),
    xcschemes.scheme(
        name = "xcschemes",
        profile = xcschemes.profile(
            launch_target = xcschemes.launch_target(
                _TOOLS["xcschemes"],
            ),
            xcode_configuration = "Release",
        ),
        run = xcschemes.run(
            args = [
                # outputDirectory
                "/tmp/pbxproj_partials/xcschemes",
                # schemeManagementOutputPath
                "/tmp/pbxproj_partials/xcschememanagement.plist",
                # autogenerationMode
                "auto",
                # defaultXcodeConfiguration
                "Debug",
                # workspace
                "/tmp/workspace",
                # installPath
                "some/project.xcodeproj",
                # extensionPointIdentifiersFile
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_extension_point_identifiers",
                # executionActionsFile
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/execution_actions_file",
                # targetsArgsEnvFile
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/targets_args_env",
                # customSchemesFile
                "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/custom_schemes_file",
                # consolidationMaps
                "--consolidation-maps",
                "/tmp/pbxproj_partials/consolidation_maps/0",
                "/tmp/pbxproj_partials/consolidation_maps/1",
                # targetAndExtensionHosts
            ],
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            launch_target = xcschemes.launch_target(
                _TOOLS["xcschemes"],
            ),
        ),
        test = xcschemes.test(
            diagnostics = _XCSCHEME_DIAGNOSTICS,
            test_targets = _TESTS["xcschemes"],
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
        "//tools/generators/pbxnativetargets": [
            "//tools/generators/pbxnativetargets:README.md",
        ],
        "//tools/generators/pbxproj_prefix": [
            "//tools/generators/pbxproj_prefix:README.md",
        ],
        "//tools/generators/pbxtargetdependencies": [
            "//tools/generators/pbxtargetdependencies:README.md",
        ],
        "//tools/generators/swift_debug_settings": [
            "//tools/generators/swift_debug_settings:README.md",
        ],
        "//tools/generators/target_build_settings": [
            "//tools/generators/target_build_settings:README.md",
        ],
        "//tools/generators/xcschemes": [
            "//tools/generators/xcschemes:README.md",
        ],
    },
    extra_files = [
        "//tools/generators:README.md",
    ],
    generation_mode = "incremental",
    project_name = "tools",
    scheme_autogeneration_mode = "none",
    top_level_targets = _TOOLS.values() + uniq(flatten(_TESTS.values())),
    xcode_configurations = _XCODE_CONFIGURATIONS,
    xcschemes = _XCSCHEMES,
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
