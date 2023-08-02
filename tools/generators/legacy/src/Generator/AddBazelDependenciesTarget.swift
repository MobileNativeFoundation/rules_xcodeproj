import GeneratorCommon
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

            // Unset our tool overrides, so scripts can use the correct versions
            "CC": "",
            "CXX": "",
            "LD": "",
            "LDPLUSPLUS": "",
            "LIBTOOL": "libtool",
            "SWIFT_EXEC": "swiftc",
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

        let bazelBuildScript = createBazelBuildScript(in: pbxProj)

        var buildPhases = [
            bazelBuildScript,
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
        in pbxProj: PBXProj
    ) -> PBXShellScriptBuildPhase {
        let script = PBXShellScriptBuildPhase(
            name: "Generate Bazel Dependencies",
            outputFileListPaths: [
                "$(INTERNAL_DIR)/\(externalFileListPath)",
                "$(INTERNAL_DIR)/\(generatedFileListPath)",
            ],
            shellScript: """
"$BAZEL_INTEGRATION_DIR/generate_bazel_dependencies.sh"

""",
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
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
