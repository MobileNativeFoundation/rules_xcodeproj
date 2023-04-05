import XcodeProj

enum XCSchemeConstants {
    // GH399: Derive `defaultLastUpgradeVersion`/make it an option
    static let defaultLastUpgradeVersion = "9999"
    static let lldbInitVersion = "1.7"
    static let posixSpawnLauncher = "Xcode.IDEFoundation.Launcher.PosixSpawn"
}

extension XCScheme.BuildableReference {
    convenience init(pbxTarget: PBXNativeTarget, referencedContainer: String) {
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
            var otherPreActions: [XCScheme.ExecutionAction] = []
            if buildMode != .xcode,
               let launchableTarget = buildActionInfo.launchableTargets
                .lazy
                .sortedLocalizedStandard(\.targetInfo.pbxTarget.name)
                .first
            {
                otherPreActions.append(
                    .symlinkDefaultToolchainUsrLibDirectory(
                        buildableReference: launchableTarget.targetInfo
                            .buildableReference
                    )
                )
            }
            buildAction = try .init(
                buildActionInfo: buildActionInfo,
                otherPreActions: otherPreActions
            )

        } else {
            buildAction = .init(
                parallelizeBuild: true,
                buildImplicitDependencies: false
            )
        }

        let launchAction: XCScheme.LaunchAction
        if let launchActionInfo = schemeInfo.launchActionInfo {
            let scriptTitle: String
            let scriptText: String
            if buildMode == .xcode {
                scriptTitle = "Update .lldbinit"
                scriptText = XCScheme.ExecutionAction.createLLDBInitScript
            } else {
                scriptTitle = "Update .lldbinit and copy dSYMs"
                scriptText = XCScheme.ExecutionAction.createLLDBInitScript +
                    "\n" + XCScheme.ExecutionAction.copyDSYMsScript
            }
            // TODO: Make this similar to `initBazelBuildOutputGroupsFile()`,
            // instead of `otherPreActions`
            let otherPreActions: [XCScheme.ExecutionAction] = [
                .createPreActionScript(
                    title: scriptTitle,
                    scriptText: scriptText,
                    buildableReference: launchActionInfo
                        .targetInfo.buildableReference
                ),
            ]
            launchAction = try .init(
                buildMode: buildMode,
                launchActionInfo: launchActionInfo,
                otherPreActions: otherPreActions
            )
        } else {
            launchAction = .init(
                runnable: nil,
                buildConfiguration: schemeInfo.defaultBuildConfigurationName
            )
        }

        let testAction: XCScheme.TestAction?
        if let testActionInfo = schemeInfo.testActionInfo {
            // TODO: Make this similar to `initBazelBuildOutputGroupsFile()`,
            // instead of `otherPreActions`
            var otherPreActions: [XCScheme.ExecutionAction] = []
            if let aTargetInfo = testActionInfo.targetInfos
                .lazy
                .sortedLocalizedStandard(\.pbxTarget.name)
                .first
            {
                otherPreActions.append(
                    .createPreActionScript(
                        title: "Update .lldbinit",
                        scriptText: ExecutionAction.createLLDBInitScript,
                        buildableReference: aTargetInfo.buildableReference
                    )
                )
            }
            testAction = try .init(
                buildMode: buildMode,
                testActionInfo: testActionInfo,
                launchActionHasRunnable: launchAction.runnable != nil,
                otherPreActions: otherPreActions
            )
        } else {
            testAction = .init(
                buildConfiguration: schemeInfo.defaultBuildConfigurationName,
                macroExpansion: nil
            )
        }

        let profileAction: XCScheme.ProfileAction?
        if let profileActionInfo = schemeInfo.profileActionInfo {
            let scriptTitle: String
            let scriptText: String
            if buildMode == .xcode {
                scriptTitle = "Update .lldbinit"
                scriptText = XCScheme.ExecutionAction.createLLDBInitScript
            } else {
                scriptTitle = "Update .lldbinit and copy dSYMs"
                scriptText = XCScheme.ExecutionAction.createLLDBInitScript +
                    "\n" + XCScheme.ExecutionAction.copyDSYMsScript
            }

            // TODO: Make this similar to `initBazelBuildOutputGroupsFile()`,
            // instead of `otherPreActions`
            let otherPreActions: [XCScheme.ExecutionAction] = [
                .createPreActionScript(
                    title: scriptTitle,
                    scriptText: scriptText,
                    buildableReference: profileActionInfo
                        .targetInfo.buildableReference
                ),
            ]
            profileAction = try .init(
                buildMode: buildMode,
                profileActionInfo: profileActionInfo,
                otherPreActions: otherPreActions
            )
        } else {
            profileAction = .init(
                buildableProductRunnable: nil,
                buildConfiguration: schemeInfo.defaultBuildConfigurationName
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
        buildActionInfo: XCSchemeInfo.BuildActionInfo,
        otherPreActions: [XCScheme.ExecutionAction] = []
    ) throws {
        try self.init(
            buildActionEntries: buildActionInfo.targets.buildActionEntries,
            preActions: buildActionInfo.preActions.map(\.executionAction) +
                buildActionInfo.targets.map(\.targetInfo).buildPreActions() +
                otherPreActions,
            postActions: buildActionInfo.postActions.map(\.executionAction),
            parallelizeBuild: true,
            buildImplicitDependencies: false
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
echo "$BAZEL_HOST_LABEL_\#(hostIndex),$BAZEL_HOST_TARGET_ID_\#(hostIndex)" \#
>> "$SCHEME_TARGET_IDS_FILE"

"""#
        } else {
            hostTargetOutputGroup = ""
        }

        let scriptText = #"""
echo "$BAZEL_LABEL,$BAZEL_TARGET_ID" >> "$SCHEME_TARGET_IDS_FILE"
\#(hostTargetOutputGroup)
"""#
        self.init(
            scriptText: scriptText,
            title: "Set Bazel Build Output Groups for \(name)",
            environmentBuildable: buildableReference
        )
    }

    /// Symlinks `$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib` to
    /// `$(BAZEL_INTEGRATION_DIR)/../lib` so that Xcode can copy sanitizers'
    /// dylibs.
    static func symlinkDefaultToolchainUsrLibDirectory(
        buildableReference: XCScheme.BuildableReference
    ) -> XCScheme.ExecutionAction {
        return .init(
            scriptText: #"""
mkdir -p "$PROJECT_DIR"

if [[ "${ENABLE_ADDRESS_SANITIZER:-}" == "YES" || \
      "${ENABLE_THREAD_SANITIZER:-}" == "YES" || \
      "${ENABLE_UNDEFINED_BEHAVIOR_SANITIZER:-}" == "YES" ]]
then
    # TODO: Support custom toolchains once clang.sh supports them
    cd "$INTERNAL_DIR" || exit 1
    ln -shfF "$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib" lib
fi
"""#,
            title: "Prepare BazelDependencies",
            environmentBuildable: buildableReference
        )
    }

    static let createLLDBInitScript = #"""
"$BAZEL_INTEGRATION_DIR/create_lldbinit.sh"
"""#

    static let copyDSYMsScript = #"""
"$BAZEL_INTEGRATION_DIR/copy_dsyms.sh"
"""#

    static func createPreActionScript(
        title: String,
        scriptText: String,
        buildableReference: XCScheme.BuildableReference
    ) -> XCScheme.ExecutionAction {
        return .init(
            scriptText: scriptText + "\n",
            title: title,
            environmentBuildable: buildableReference
        )
    }
}

extension XCScheme.CommandLineArguments {
    convenience init?(xcSchemeInfoArgs args: [String]?) {
        guard let args = args else {
            return nil
        }
        guard !args.isEmpty else {
            return nil
        }
        self.init(
            arguments: args.map { .init(name: $0, enabled: true) }
        )
    }
}

extension XCScheme.TestAction {
    convenience init(
        buildMode: BuildMode,
        testActionInfo: XCSchemeInfo.TestActionInfo,
        launchActionHasRunnable: Bool,
        otherPreActions: [XCScheme.ExecutionAction] = []
    ) throws {
        let commandlineArguments = XCScheme.CommandLineArguments(
            xcSchemeInfoArgs: testActionInfo.args
        )
        let shouldUseLaunchSchemeArgsEnv = launchActionHasRunnable &&
            commandlineArguments == nil && testActionInfo.env == nil

        let environmentVariables: [XCScheme.EnvironmentVariable]?
        if shouldUseLaunchSchemeArgsEnv {
            environmentVariables = nil
        } else {
            environmentVariables = buildMode.launchEnvironmentVariables.merged(
                with: (testActionInfo.env ?? [:]).asLaunchEnvironmentVariables()
            )
        }

        try self.init(
            buildConfiguration: testActionInfo.buildConfigurationName,
            macroExpansion: testActionInfo.macroExpansion,
            testables: testActionInfo.targetInfos
                .filter(\.pbxTarget.isTestable)
                .sortedLocalizedStandard(\.pbxTarget.name)
                .map { .init(skipped: false, buildableReference: $0.buildableReference) },
            preActions: testActionInfo.preActions.map(\.executionAction) +
                otherPreActions,
            postActions: testActionInfo.postActions.map(\.executionAction),
            shouldUseLaunchSchemeArgsEnv: shouldUseLaunchSchemeArgsEnv,
            enableAddressSanitizer: testActionInfo.diagnostics.sanitizers
                .address,
            enableThreadSanitizer: testActionInfo.diagnostics.sanitizers
                .thread,
            enableUBSanitizer: testActionInfo.diagnostics.sanitizers
                .undefinedBehavior,
            commandlineArguments: commandlineArguments,
            environmentVariables: (environmentVariables?.isEmpty ?? true) ?
                nil : environmentVariables
        )
    }
}

extension XCScheme.LaunchAction {
    convenience init(
        buildMode: BuildMode,
        launchActionInfo: XCSchemeInfo.LaunchActionInfo,
        otherPreActions: [XCScheme.ExecutionAction]
    ) throws {
        let commandlineArguments = XCScheme.CommandLineArguments(
            xcSchemeInfoArgs: launchActionInfo.args
        )
        let environmentVariables = buildMode.launchEnvironmentVariables.merged(
            with: launchActionInfo.env.asLaunchEnvironmentVariables()
        )

        try self.init(
            runnable: launchActionInfo.runnable,
            buildConfiguration: launchActionInfo.buildConfigurationName,
            preActions: otherPreActions,
            macroExpansion: launchActionInfo.macroExpansion,
            selectedDebuggerIdentifier: launchActionInfo.debugger,
            selectedLauncherIdentifier: launchActionInfo.launcher,
            askForAppToLaunch: launchActionInfo.askForAppToLaunch ? true : nil,
            customWorkingDirectory: launchActionInfo.workingDirectory,
            useCustomWorkingDirectory: launchActionInfo.workingDirectory != nil,
            enableAddressSanitizer: launchActionInfo.diagnostics.sanitizers
                .address,
            enableThreadSanitizer: launchActionInfo.diagnostics.sanitizers
                .thread,
            enableUBSanitizer: launchActionInfo.diagnostics.sanitizers
                .undefinedBehavior,
            commandlineArguments: commandlineArguments,
            environmentVariables: environmentVariables.isEmpty ? nil : environmentVariables,
            launchAutomaticallySubstyle: launchActionInfo.targetInfo.productType
                .launchAutomaticallySubstyle
        )
    }
}

extension XCScheme.ProfileAction {
    convenience init(
        buildMode: BuildMode,
        profileActionInfo: XCSchemeInfo.ProfileActionInfo,
        otherPreActions: [XCScheme.ExecutionAction]
    ) throws {
        let commandlineArguments = XCScheme.CommandLineArguments(
            xcSchemeInfoArgs: profileActionInfo.args
        )
        let shouldUseLaunchSchemeArgsEnv = commandlineArguments == nil &&
            profileActionInfo.env == nil

        let environmentVariables: [XCScheme.EnvironmentVariable]?
        if shouldUseLaunchSchemeArgsEnv {
            environmentVariables = nil
        } else {
            environmentVariables = buildMode.launchEnvironmentVariables.merged(
                with: (profileActionInfo.env ?? [:])
                    .asLaunchEnvironmentVariables()
            )
        }

        try self.init(
            buildableProductRunnable: profileActionInfo.runnable,
            buildConfiguration: profileActionInfo.buildConfigurationName,
            preActions: otherPreActions,
            macroExpansion: profileActionInfo.macroExpansion,
            shouldUseLaunchSchemeArgsEnv: shouldUseLaunchSchemeArgsEnv,
            customWorkingDirectory: profileActionInfo.workingDirectory,
            useCustomWorkingDirectory:
                profileActionInfo.workingDirectory != nil,
            commandlineArguments: commandlineArguments,
            environmentVariables: (environmentVariables?.isEmpty ?? true) ?
                nil : environmentVariables
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

extension Dictionary where Key == String, Value == [BazelLabel: TargetID] {
    /// Tries to find a `TargetID` for `label` with `preferredConfiguration`,
    /// and if that fails, find the first one alphabetically. Throw if none are
    /// found.
    func targetID(
        for label: BazelLabel,
        preferredConfiguration: String
    ) -> TargetID? {
        if let targetID = self[preferredConfiguration]?[label] {
            return targetID
        }

        for (_, targetIDsByLabel) in sorted(by: { $0.key < $1.key }) {
            if let targetID = targetIDsByLabel[label] {
                return targetID
            }
        }

        return nil
    }
}
