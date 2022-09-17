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

    static func addBazelDependenciesTarget(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        forceBazelDependencies: Bool,
        indexImport: FilePath,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        resolvedExternalRepositories: [(Path, Path)],
        bazelConfig: String,
        xcodeprojBazelLabel: BazelLabel,
        xcodeprojConfiguration: String,
        preBuildScript: FilePath?,
        postBuildScript: FilePath?,
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

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: [
                "BAZEL_CONFIG": bazelConfig,
                "BAZEL_PACKAGE_BIN_DIR": "rules_xcodeproj",
                "CALCULATE_OUTPUT_GROUPS_SCRIPT": """
$(BAZEL_INTEGRATION_DIR)/calculate_output_groups.py
""",
                "GENERATOR_LABEL": xcodeprojBazelLabel,
                "GENERATOR_PACKAGE_BIN_DIR": """
\(xcodeprojConfiguration)/bin/\(xcodeprojBazelLabel.package)
""",
                "GENERATOR_TARGET_NAME": xcodeprojBazelLabel.name,
                "INDEX_DATA_STORE_DIR": "$(INDEX_DATA_STORE_DIR)",
                "INDEX_IMPORT":try filePathResolver
                    .resolve(indexImport, useBazelOut: true).string,
                "RESOLVED_EXTERNAL_REPOSITORIES": resolvedExternalRepositories
                    // Sorted by length to ensure that subdirectories are listed first
                    .sorted { $0.0.string.count > $1.0.string.count }
                    .map { #""\#($0)" "\#($1)""# }
                    .joined(separator: " "),
                "RULES_XCODEPROJ_BUILD_MODE": buildMode.rawValue,
                // We have to support only a single platform to prevent issues
                // with duplicated outputs during Index Build, but it also
                // has to be a platform that one of the targets uses, otherwise
                // it's not invoked at all. Index Build is so weird...
                "SUPPORTED_PLATFORMS": projectPlatforms.sorted()
                    .first!.variant.rawValue,
                "SUPPORTS_MACCATALYST": true,
                "TARGET_NAME": "BazelDependencies",
            ]
        )
        pbxProj.add(object: debugConfiguration)
        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        pbxProj.add(object: configurationList)

        let bazelBuildScript = try createBazelBuildScript(
            in: pbxProj,
            buildMode: buildMode,
            targets: consolidatedTargets.targets.values
                .flatMap { $0.sortedTargets },
            files: files,
            filePathResolver: filePathResolver,
            xcodeprojBazelLabel: xcodeprojBazelLabel,
            xcodeprojConfiguration: xcodeprojConfiguration
        )

        let createLLDBSettingsModuleScript =
            try createCreateLLDBSettingsModuleScript(
                in: pbxProj,
                filePathResolver: filePathResolver
            )

        var buildPhases = [
            bazelBuildScript,
            createLLDBSettingsModuleScript,
        ]

        if let preBuildScript = preBuildScript {
            let scriptPath = try filePathResolver
                .resolve(preBuildScript,
                         forceAbsoluteProjectPath: true,
                         mode: .script).string
            let script = try createBuildScript(
                in: pbxProj,
                name: "Pre-build",
                scriptPath: scriptPath
            )
            buildPhases.insert(script, at: 0)
        }

        if let postBuildScript = postBuildScript {
            let scriptPath = try filePathResolver
                .resolve(postBuildScript,
                         forceAbsoluteProjectPath: true,
                         mode: .script).string
            let script = try createBuildScript(
                in: pbxProj,
                name: "Post-build",
                scriptPath: scriptPath
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
            // TODO: Generate this value
            "CreatedOnToolsVersion": "13.2.1",
        ]
        pbxProject.setTargetAttributes(attributes, target: pbxTarget)

        return pbxTarget
    }

    private static func createBazelBuildScript(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        targets: [Target],
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: BazelLabel,
        xcodeprojConfiguration: String
    ) throws -> PBXShellScriptBuildPhase {
        let hasGeneratedFiles = files.containsGeneratedFiles

        var outputFileListPaths: [String] = []
        if files.containsExternalFiles {
            let externalFilesList = try filePathResolver
                .resolve(.internal(externalFileListPath))
                .string
            outputFileListPaths.append(externalFilesList)
        }
        if hasGeneratedFiles {
            let generatedFileList = try filePathResolver
                .resolve(.internal(generatedFileListPath))
                .string
            outputFileListPaths.append(generatedFileList)
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
"$BAZEL_INTEGRATION_DIR/bazel_build.sh"

""",
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createCreateLLDBSettingsModuleScript(
        in pbxProj: PBXProj,
        filePathResolver: FilePathResolver
    ) throws -> PBXShellScriptBuildPhase {
        let script = PBXShellScriptBuildPhase(
            name: "Create swift_debug_settings.py",
            inputPaths: [
                try filePathResolver
                    .resolve(.internal(lldbSwiftSettingsModulePath))
                    .string
            ],
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
        scriptPath: String
    ) throws -> PBXShellScriptBuildPhase {
        let script = PBXShellScriptBuildPhase(
            name: "\(name) Run Script",
            shellScript: scriptPath.quoted,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: script)

        return script
    }
}

private extension Dictionary where Key == FilePath {
    var containsExternalFiles: Bool { keys.containsExternalFiles }
    var containsGeneratedFiles: Bool { keys.containsGeneratedFiles }

    var containsInfoPlists: Bool {
        contains(where: { filePath, _ in
            return filePath.type == .generated
                && filePath.path.lastComponent == "Info.plist"
        })
    }
}

private extension Sequence where Element == FilePath {
    var containsExternalFiles: Bool { contains { $0.type == .external } }
    var containsGeneratedFiles: Bool { contains { $0.type == .generated } }
}
