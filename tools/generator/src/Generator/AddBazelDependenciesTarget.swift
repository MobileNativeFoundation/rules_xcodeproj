import PathKit
import XcodeProj

extension Generator {
    // swiftlint:disable:next function_parameter_count
    static func addBazelDependenciesTarget(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        minimumXcodeVersion: SemanticVersion,
        xcodeConfigurations: Set<String>,
        defaultXcodeConfiguration: String,
        targetIdsFile: String,
        indexImport: String,
        usesExternalFileList: Bool,
        usesGeneratedFileList: Bool,
        bazelConfig _: String,
        preBuildScript: String?,
        postBuildScript: String?,
        consolidatedTargets: ConsolidatedTargets
    ) throws -> PBXAggregateTarget? {
        guard !consolidatedTargets.targets.isEmpty else {
            return nil
        }

        let pbxProject = pbxProj.rootObject!

        let projectPlatforms: Set<Platform> = consolidatedTargets.targets.values
            .reduce(into: []) { platforms, consolidatedTarget in
                consolidatedTarget.targets.values
                    .forEach { platforms.insert($0.platform) }
            }

        let supportedPlatforms = projectPlatforms
            .sorted()
            .map(\.variant.rawValue)
            .uniqued()

        var buildSettings: BuildSettings = [
            "BAZEL_PACKAGE_BIN_DIR": "rules_xcodeproj",
            "CALCULATE_OUTPUT_GROUPS_SCRIPT": """
$(BAZEL_INTEGRATION_DIR)/calculate_output_groups.py
""",
            "INDEX_DATA_STORE_DIR": "$(INDEX_DATA_STORE_DIR)",
            "INDEX_IMPORT": indexImport,
            "INDEXING_SUPPORTED_PLATFORMS__": """
$(INDEXING_SUPPORTED_PLATFORMS__NO)
""",
            "INDEXING_SUPPORTED_PLATFORMS__NO": supportedPlatforms
                .joined(separator: " "),
            // We have to support only a single platform to prevent issues
            // with duplicated outputs during Index Build, but it also
            // has to be a platform that one of the targets uses, otherwise
            // it's not invoked at all. Index Build is so weird...
            "INDEXING_SUPPORTED_PLATFORMS__YES": supportedPlatforms.first!,
            "SUPPORTED_PLATFORMS": """
$(INDEXING_SUPPORTED_PLATFORMS__$(INDEX_ENABLE_BUILD_ARENA))
""",
            "SUPPORTS_MACCATALYST": true,
            "TARGET_IDS_FILE": targetIdsFile,
            "TARGET_NAME": "BazelDependencies",
        ]

        if buildMode.usesBazelModeBuildScripts {
            buildSettings["INDEX_DISABLE_SCRIPT_EXECUTION"] = true
        }

        var buildConfigurations: [XCBuildConfiguration] = []
        for xcodeConfiguration in xcodeConfigurations.sorted() {
            let buildConfiguration = XCBuildConfiguration(
                name: xcodeConfiguration,
                buildSettings: buildSettings
            )
            buildConfigurations.append(buildConfiguration)
            pbxProj.add(object: buildConfiguration)
        }

        let configurationList = XCConfigurationList(
            buildConfigurations: buildConfigurations,
            defaultConfigurationName: defaultXcodeConfiguration
        )
        pbxProj.add(object: configurationList)

        let bazelBuildScript = createBazelBuildScript(
            in: pbxProj,
            buildMode: buildMode,
            targets: consolidatedTargets.targets.values
                .flatMap(\.sortedTargets),
            usesExternalFileList: usesExternalFileList,
            usesGeneratedFileList: usesGeneratedFileList
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
        targets _: [Target],
        usesExternalFileList: Bool,
        usesGeneratedFileList: Bool
    ) -> PBXShellScriptBuildPhase {

        var outputFileListPaths: [String] = []
        if usesExternalFileList {
            outputFileListPaths.append(
                "$(INTERNAL_DIR)/\(externalFileListPath)"
            )
        }
        if usesGeneratedFileList {
            outputFileListPaths.append(
                "$(INTERNAL_DIR)/\(generatedFileListPath)"
            )
        }

        let name: String
        if buildMode.usesBazelModeBuildScripts {
            name = "Bazel Build"
        } else if usesGeneratedFileList {
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
            inputPaths: ["$(BAZEL_INTEGRATION_DIR)/$(CONFIGURATION)-swift_debug_settings.py"],
            outputPaths: ["$(OBJROOT)/$(CONFIGURATION)/swift_debug_settings.py"],
            shellScript: #"""
perl -pe '
  # Replace "__BAZEL_XCODE_DEVELOPER_DIR__" with "$(DEVELOPER_DIR)"
  s/__BAZEL_XCODE_DEVELOPER_DIR__/\$(DEVELOPER_DIR)/g;

  # Replace "__BAZEL_XCODE_SDKROOT__" with "$(SDKROOT)"
  s/__BAZEL_XCODE_SDKROOT__/\$(SDKROOT)/g;

  # Replace build settings with their values
  s/
    \$             # Match a dollar sign
    (\()?          # Optionally match an opening parenthesis and capture it
    ([a-zA-Z_]\w*) # Match a variable name and capture it
    (?(1)\))       # If an opening parenthesis was captured, match a closing parenthesis
  /$ENV{$2}/gx;    # Replace the entire matched string with the value of the corresponding environment variable

' "$SCRIPT_INPUT_FILE_0" > "$SCRIPT_OUTPUT_FILE_0"

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
