import PBXProj

extension Generator {
    /// Calculates the BazelDependencies `PBXProj` partial.
    static func bazelDependenciesPartial(
        buildSettings: String,
        defaultXcodeConfiguration: String,
        postBuildRunScript: String?,
        preBuildRunScript: String?,
        xcodeConfigurations: [String]
    ) -> String {
        // Build phases

        var buildPhases: [(id: String, element: String)] = []

        if let preBuildRunScript = preBuildRunScript {
            let id = Identifiers.BazelDependencies.preBuildScript
            buildPhases.append((
                id: id,
                element: #"""
		\#(id) = \#(preBuildRunScript);
"""#
            ))
        }

        buildPhases.append((
            id: Identifiers.BazelDependencies.bazelBuild,
            element: #"""
		\#(Identifiers.BazelDependencies.bazelBuild) = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Generate Bazel Dependendencies";
			outputFileListPaths = (
				"$(INTERNAL_DIR)/external.xcfilelist",
				"$(INTERNAL_DIR)/generated.xcfilelist",
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "\"$BAZEL_INTEGRATION_DIR/generate_bazel_dependencies.sh\"\n";
			showEnvVarsInLog = 0;
		};
"""#
        ))

        buildPhases.append((
            id: Identifiers.BazelDependencies.createSwiftDebugSettings,
            element: #"""
		\#(Identifiers.BazelDependencies.createSwiftDebugSettings) = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(BAZEL_INTEGRATION_DIR)/$(CONFIGURATION)-swift_debug_settings.py",
			);
			name = "Create swift_debug_settings.py";
			outputPaths = (
				"$(OBJROOT)/$(CONFIGURATION)/swift_debug_settings.py",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = \#(swiftDebugSettingScript.pbxProjEscaped);
			showEnvVarsInLog = 0;
		};
"""#
        ))

        if let postBuildRunScript = postBuildRunScript {
            let id = Identifiers.BazelDependencies.postBuildScript
            buildPhases.append((
                id: id,
                element: #"""
		\#(id) = \#(postBuildRunScript);
"""#
            ))
        }

        // Build configurations

        let buildConfigurations =  xcodeConfigurations
            .enumerated()
            .map { index, name in
                let id = Identifiers.BazelDependencies
                    .buildConfiguration(name, index: UInt8(index))
                return (
                    id: id,
                    element: #"""
		\#(id) = {
			isa = XCBuildConfiguration;
			buildSettings = \#(buildSettings);
			name = \#(name.pbxProjEscaped);
		};
"""#
                )
            }

        // Final form

        // The tabs for indenting are intentional. The trailing newlines are
        // intentional, as `cat` needs them to concatenate the partials
        // correctly.
        return #"""
\#(buildPhases.map(\.element).joined(separator: "\n"))
\#(buildConfigurations.map(\.element).joined(separator: "\n"))
		\#(Identifiers.BazelDependencies.buildConfigurationList) = {
			isa = XCConfigurationList;
			buildConfigurations = (
\#(
    buildConfigurations
        .map { id, _ in "\t\t\t\t\(id),"}.joined(separator: "\n")
)
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = \#(
                defaultXcodeConfiguration.pbxProjEscaped
            );
		};
		\#(Identifiers.BazelDependencies.id) = {
			isa = PBXAggregateTarget;
			buildConfigurationList = \#(
                Identifiers.BazelDependencies.buildConfigurationList
            );
			buildPhases = (
\#(buildPhases.map { id, _ in "\t\t\t\t\(id)," }.joined(separator: "\n"))
			);
			dependencies = (
			);
			name = BazelDependencies;
			productName = BazelDependencies;
		};

"""#
    }

    // Pulled out for readability
    private static let swiftDebugSettingScript = #"""
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

"""#
}
