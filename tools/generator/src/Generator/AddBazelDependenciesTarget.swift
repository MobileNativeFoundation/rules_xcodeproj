import PathKit
import XcodeProj

extension Generator {
    static func needsBazelDependenciesTarget(
        buildMode: BuildMode,
        forceBazelDependencies: Bool,
        files: [FilePath: File],
        hasTargets: Bool
    ) -> Bool {
        guard hasTargets else {
            return false
        }

        return (forceBazelDependencies ||
                buildMode.usesBazelModeBuildScripts ||
                files.containsExternalFiles ||
                files.containsGeneratedFiles)
    }

    // swiftlint:disable:next function_parameter_count
    static func addBazelDependenciesTarget(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        forceBazelDependencies: Bool,
        minimumXcodeVersion: SemanticVersion,
        indexImport: String,
        files: [FilePath: File],
        bazelConfig: String,
        generatorLabel: BazelLabel,
        preBuildScript: String?,
        postBuildScript: String?,
        consolidatedTargets: ConsolidatedTargets
    ) throws -> PBXAggregateTarget? {
        guard needsBazelDependenciesTarget(
            buildMode: buildMode,
            forceBazelDependencies: forceBazelDependencies,
            files: files,
            hasTargets: !consolidatedTargets.targets.isEmpty
        ) else {
            return nil
        }

        let pbxProject = pbxProj.rootObject!

        let projectPlatforms: Set<Platform> = consolidatedTargets.targets.values
            .reduce(into: []) { platforms, consolidatedTarget in
                consolidatedTarget.targets.values
                    .forEach { platforms.insert($0.platform) }
            }

        var buildSettings: BuildSettings = [
            "BAZEL_PACKAGE_BIN_DIR": "rules_xcodeproj",
            "CALCULATE_OUTPUT_GROUPS_SCRIPT": """
$(BAZEL_INTEGRATION_DIR)/calculate_output_groups.py
""",
            "INDEX_DATA_STORE_DIR": "$(INDEX_DATA_STORE_DIR)",
            "INDEX_IMPORT": indexImport,
            // We have to support only a single platform to prevent issues
            // with duplicated outputs during Index Build, but it also
            // has to be a platform that one of the targets uses, otherwise
            // it's not invoked at all. Index Build is so weird...
            "SUPPORTED_PLATFORMS": projectPlatforms.sorted()
                .first!.variant.rawValue,
            "SUPPORTS_MACCATALYST": true,
            "TARGET_NAME": "BazelDependencies",
        ]

        if buildMode.usesBazelModeBuildScripts {
            buildSettings["INDEX_DISABLE_SCRIPT_EXECUTION"] = true
        }

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: buildSettings
        )
        pbxProj.add(object: debugConfiguration)
        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        pbxProj.add(object: configurationList)

        let bazelBuildScript = createBazelBuildScript(
            in: pbxProj,
            buildMode: buildMode,
            targets: consolidatedTargets.targets.values
                .flatMap { $0.sortedTargets },
            files: files,
            generatorLabel: generatorLabel
        )

        let createLLDBSettingsModuleScript =
            createCreateLLDBSettingsModuleScript(in: pbxProj)

        var buildPhases = [
            bazelBuildScript,
            createLLDBSettingsModuleScript,
        ]

        if let preBuildScript = preBuildScript {
            let script = createBuildScript(
                in: pbxProj,
                name: "Pre-build",
                script: preBuildScript,
                alwaysOutOfDate: true
            )
            buildPhases.insert(script, at: 0)
        }

        if let postBuildScript = postBuildScript {
            let script = createBuildScript(
                in: pbxProj,
                name: "Post-build",
                script: postBuildScript,
                alwaysOutOfDate: true
            )
            buildPhases.append(script)
        }

        let pbxTarget = PBXAggregateTarget(
            name: "BazelDependencies",
            buildConfigurationList: configurationList,
            buildPhases: buildPhases,
            productName: "BazelDependencies"
        )
        pbxProj.add(object: pbxTarget)
        pbxProject.targets.append(pbxTarget)

        let attributes: [String: Any] = [
            "CreatedOnToolsVersion": minimumXcodeVersion.full,
        ]
        pbxProject.setTargetAttributes(attributes, target: pbxTarget)

        return pbxTarget
    }

    private static func createBazelBuildScript(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        targets: [Target],
        files: [FilePath: File],
        generatorLabel: BazelLabel
    ) -> PBXShellScriptBuildPhase {
        let hasGeneratedFiles = files.containsGeneratedFiles

        var outputFileListPaths: [String] = []
        if files.containsExternalFiles {
            outputFileListPaths.append(
                FilePathResolver.resolveInternal(externalFileListPath)
            )
        }
        if hasGeneratedFiles {
            outputFileListPaths.append(
                FilePathResolver.resolveInternal(generatedFileListPath)
            )
        }

        let name: String
        if buildMode.usesBazelModeBuildScripts {
            name = "Bazel Build"
        } else if hasGeneratedFiles {
            name = "Generate Files"
        } else {
            name = "Fetch External Repositories"
        }

        let script = PBXShellScriptBuildPhase(
            name: name,
            outputFileListPaths: outputFileListPaths,
            shellScript: """
"$BAZEL_INTEGRATION_DIR/generate_bazel_dependencies.sh"

""",
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createCreateLLDBSettingsModuleScript(
        in pbxProj: PBXProj
    ) -> PBXShellScriptBuildPhase {
        let script = PBXShellScriptBuildPhase(
            name: "Create swift_debug_settings.py",
            inputPaths: ["$(BAZEL_INTEGRATION_DIR)/swift_debug_settings.py"],
            outputPaths: ["$(OBJROOT)/swift_debug_settings.py"],
            shellScript: #"""
perl -pe 's/\$(\()?([a-zA-Z_]\w*)(?(1)\))/$ENV{$2}/g' \
  "$SCRIPT_INPUT_FILE_0" > "$SCRIPT_OUTPUT_FILE_0"

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createBuildScript(
        in pbxProj: PBXProj,
        name: String,
        script: String,
        alwaysOutOfDate: Bool = false
    ) -> PBXShellScriptBuildPhase {
        let script = PBXShellScriptBuildPhase(
            name: "\(name) Run Script",
            shellScript: "\(script)\n",
            showEnvVarsInLog: false,
            alwaysOutOfDate: alwaysOutOfDate
        )
        pbxProj.add(object: script)

        return script
    }
}

private extension Dictionary where Key == FilePath {
    var containsExternalFiles: Bool { keys.containsExternalFiles }
    var containsGeneratedFiles: Bool { keys.containsGeneratedFiles }
}

private extension Sequence where Element == FilePath {
    var containsExternalFiles: Bool { contains { $0.type == .external } }
    var containsGeneratedFiles: Bool { contains { $0.type == .generated } }
}
