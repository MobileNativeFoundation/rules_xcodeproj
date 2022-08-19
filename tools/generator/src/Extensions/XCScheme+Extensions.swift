import XcodeProj

enum XCSchemeConstants {
    // GH399: Derive the defaultLastUpgradeVersion
    static let defaultLastUpgradeVersion = "1320"
    static let lldbInitVersion = "1.7"
    static let posixSpawnLauncher = "Xcode.IDEFoundation.Launcher.PosixSpawn"
    static let customLLDBInitFile = "$(BAZEL_LLDB_INIT)"
}

extension XCScheme.BuildableReference {
    convenience init(pbxTarget: PBXTarget, referencedContainer: String) {
        self.init(
            referencedContainer: referencedContainer,
            blueprint: pbxTarget,
            buildableName: pbxTarget.buildableName,
            blueprintName: pbxTarget.name
        )
    }
}

extension XCScheme {
    convenience init(
        buildMode: BuildMode,
        schemeInfo: XCSchemeInfo
    ) throws {
        let buildAction: XCScheme.BuildAction?
        if let buildActionInfo = schemeInfo.buildActionInfo {
            buildAction = try .init(buildActionInfo: buildActionInfo)
        } else {
            buildAction = .init(
                parallelizeBuild: true,
                buildImplicitDependencies: true
            )
        }

        let testAction: XCScheme.TestAction?
        if let testActionInfo = schemeInfo.testActionInfo {
            testAction = .init(buildMode: buildMode, testActionInfo: testActionInfo)
        } else {
            testAction = .init(
                buildConfiguration: .defaultBuildConfigurationName,
                macroExpansion: nil,
                customLLDBInitFile: XCSchemeConstants.customLLDBInitFile
            )
        }

        let launchAction: XCScheme.LaunchAction?
        if let launchActionInfo = schemeInfo.launchActionInfo {
            launchAction = try .init(buildMode: buildMode, launchActionInfo: launchActionInfo)
        } else {
            launchAction = .init(
                runnable: nil,
                buildConfiguration: .defaultBuildConfigurationName,
                customLLDBInitFile: XCSchemeConstants.customLLDBInitFile
            )
        }

        let profileAction: XCScheme.ProfileAction?
        if let profileActionInfo = schemeInfo.profileActionInfo {
            profileAction = .init(profileActionInfo: profileActionInfo)
        } else {
            profileAction = .init(
                buildableProductRunnable: nil,
                buildConfiguration: .defaultBuildConfigurationName
            )
        }

        self.init(
            name: schemeInfo.name,
            lastUpgradeVersion: XCSchemeConstants.defaultLastUpgradeVersion,
            version: XCSchemeConstants.lldbInitVersion,
            buildAction: buildAction,
            testAction: testAction,
            launchAction: launchAction,
            profileAction: profileAction,
            analyzeAction: .init(analyzeActionInfo: schemeInfo.analyzeActionInfo),
            archiveAction: .init(archiveActionInfo: schemeInfo.archiveActionInfo),
            wasCreatedForAppExtension: schemeInfo.wasCreatedForAppExtension ? true : nil
        )
    }
}

extension XCScheme.BuildAction {
    convenience init(
        buildActionInfo: XCSchemeInfo.BuildActionInfo
    ) throws {
        self.init(
            buildActionEntries: try buildActionInfo.targets.buildActionEntries,
            preActions: try buildActionInfo.targets.map(\.targetInfo).buildPreActions(),
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
    }
}

extension XCScheme.ExecutionAction {
    /// Initialize the output file for Build with Bazel mode.
    static func initBazelBuildOutputGroupsFile(
        buildableReference: XCScheme.BuildableReference
    ) -> XCScheme.ExecutionAction {
        return .init(
            scriptText: #"""
mkdir -p "${SCHEME_TARGET_IDS_FILE%/*}"
if [[ -s "$SCHEME_TARGET_IDS_FILE" ]]; then
    rm "$SCHEME_TARGET_IDS_FILE"
fi

"""#,
            title: "Initialize Bazel Build Output Groups File",
            environmentBuildable: buildableReference
        )
    }

    /// Create an `ExecutionAction` that builds with Bazel.
    convenience init(
        buildFor buildableReference: XCScheme.BuildableReference,
        name: String,
        hostIndex: Int?
    ) {
        let hostTargetOutputGroup: String
        if let hostIndex = hostIndex {
            // The extra blank line at the end of this string literal is purposeful. It ensures that
            // a newline is added to the resulting string, if the host information is added to the
            // script.
            hostTargetOutputGroup = #"""
echo "$BAZEL_HOST_TARGET_ID_\#(hostIndex)" \#
>> "$SCHEME_TARGET_IDS_FILE"

"""#
        } else {
            hostTargetOutputGroup = ""
        }

        let scriptText = #"""
echo "$BAZEL_TARGET_ID" >> "$SCHEME_TARGET_IDS_FILE"
\#(hostTargetOutputGroup)
"""#
        self.init(
            scriptText: scriptText,
            title: "Set Bazel Build Output Groups for \(name)",
            environmentBuildable: buildableReference
        )
    }
}

extension XCScheme.TestAction {
    convenience init(buildMode: BuildMode, testActionInfo: XCSchemeInfo.TestActionInfo) {
        let customArgs = testActionInfo.args.isEmpty ? nil :
            XCScheme.CommandLineArguments(
                arguments: testActionInfo.args.map { .init(name: $0, enabled: true) }
            )
        let customEnvVars = testActionInfo.env.isEmpty ? nil :
            buildMode.launchEnvironmentVariables.merged(
                with: testActionInfo.env.asLaunchEnvironmentVariables()
            )
        let shouldUseLaunchSchemeArgsEnv = (customArgs == nil && customEnvVars == nil)

        self.init(
            buildConfiguration: testActionInfo.buildConfigurationName,
            macroExpansion: nil,
            testables: testActionInfo.targetInfos
                .filter(\.pbxTarget.isTestable)
                .sortedLocalizedStandard(\.pbxTarget.name)
                .map { .init(skipped: false, buildableReference: $0.buildableReference) },
            shouldUseLaunchSchemeArgsEnv: shouldUseLaunchSchemeArgsEnv,
            commandlineArguments: customArgs,
            environmentVariables: customEnvVars,
            customLLDBInitFile: XCSchemeConstants.customLLDBInitFile
        )
    }
}

extension XCScheme.LaunchAction {
    convenience init(buildMode: BuildMode, launchActionInfo: XCSchemeInfo.LaunchActionInfo) throws {
        let environmentVariables = buildMode.launchEnvironmentVariables.merged(
            with: launchActionInfo.env.asLaunchEnvironmentVariables()
        )
        // GH933: Add support for custom working directory once it is available in tuist/XcodeProj.
        self.init(
            runnable: launchActionInfo.runnable,
            buildConfiguration: launchActionInfo.buildConfigurationName,
            macroExpansion: try launchActionInfo.macroExpansion,
            selectedDebuggerIdentifier: launchActionInfo.debugger,
            selectedLauncherIdentifier: launchActionInfo.launcher,
            askForAppToLaunch: launchActionInfo.askForAppToLaunch ? true : nil,
            commandlineArguments: launchActionInfo.args.isEmpty ? nil :
                .init(arguments: launchActionInfo.args.map { .init(name: $0, enabled: true) }),
            environmentVariables: environmentVariables.isEmpty ? nil : environmentVariables,
            launchAutomaticallySubstyle: launchActionInfo.targetInfo.productType
                .launchAutomaticallySubstyle,
            customLLDBInitFile: XCSchemeConstants.customLLDBInitFile
        )
    }
}

extension XCScheme.ProfileAction {
    convenience init(profileActionInfo: XCSchemeInfo.ProfileActionInfo) {
        self.init(
            buildableProductRunnable: profileActionInfo.runnable,
            buildConfiguration: profileActionInfo.buildConfigurationName
        )
    }
}

extension XCScheme.AnalyzeAction {
    convenience init(analyzeActionInfo: XCSchemeInfo.AnalyzeActionInfo) {
        self.init(buildConfiguration: analyzeActionInfo.buildConfigurationName)
    }
}

extension XCScheme.ArchiveAction {
    convenience init(archiveActionInfo: XCSchemeInfo.ArchiveActionInfo) {
        self.init(
            buildConfiguration: archiveActionInfo.buildConfigurationName,
            revealArchiveInOrganizer: true
        )
    }
}

extension Sequence where Element == XCScheme.BuildableReference {
    var inStableOrder: [XCScheme.BuildableReference] {
        return sortedLocalizedStandard(\.blueprintName)
    }
}

extension Sequence where Element == XCScheme.BuildAction.Entry.BuildFor {
    static var `default`: [XCScheme.BuildAction.Entry.BuildFor] {
        return [.running, .testing, .profiling, .archiving, .analyzing]
    }
}
