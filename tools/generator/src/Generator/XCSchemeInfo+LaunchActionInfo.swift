import XcodeProj

extension XCSchemeInfo {
    struct LaunchActionInfo: Equatable {
        let buildConfigurationName: String
        let targetInfo: XCSchemeInfo.TargetInfo
        let args: [String]
        let diagnostics: DiagnosticsInfo
        let env: [String: String]
        let workingDirectory: String?

        init(
            buildConfigurationName: String,
            targetInfo: XCSchemeInfo.TargetInfo,
            args: [String] = [],
            diagnostics: DiagnosticsInfo = .init(diagnostics: .init()),
            env: [String: String] = [:],
            workingDirectory: String? = nil
        ) throws {
            guard targetInfo.productType.isLaunchable else {
                throw PreconditionError(message: """
An `XCSchemeInfo.LaunchActionInfo` should have a launchable \
`XCSchemeInfo.TargetInfo` value.
""")
            }
            self.buildConfigurationName = buildConfigurationName
            self.targetInfo = targetInfo
            self.args = args
            self.diagnostics = diagnostics
            self.env = env
            self.workingDirectory = workingDirectory
        }
    }
}

// MARK: Host Resolution Initializer

extension XCSchemeInfo.LaunchActionInfo {
    /// Create a copy of the `LaunchActionInfo` with the host in the
    /// `TargetInfo` resolved.
    init?<TargetInfos: Sequence>(
        resolveHostsFor launchActionInfo: XCSchemeInfo.LaunchActionInfo?,
        topLevelTargetInfos: TargetInfos
    ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        guard let original = launchActionInfo else {
          return nil
        }
        try self.init(
            buildConfigurationName: original.buildConfigurationName,
            targetInfo: .init(
                resolveHostFor: original.targetInfo,
                topLevelTargetInfos: topLevelTargetInfos
            ),
            args: original.args,
            diagnostics: original.diagnostics,
            env: original.env,
            workingDirectory: original.workingDirectory
        )
    }
}

// MARK: `runnable`

extension XCSchemeInfo.LaunchActionInfo {
    var runnable: XCScheme.Runnable? {
        // We want to provide a `LaunchActionInfo`, but we do not want to
        // provide a `runnable`, if it is testable.
        if targetInfo.pbxTarget.isTestable {
            return nil
        }
        if targetInfo.isWidgetKitExtension {
            return XCScheme.RemoteRunnable(
                buildableReference: targetInfo.buildableReference,
                bundleIdentifier: "com.apple.springboard",
                runnableDebuggingMode: "2"
            )
        } else if targetInfo.isMessageAppExtension {
            return XCScheme.RemoteRunnable(
                buildableReference: targetInfo.buildableReference,
                bundleIdentifier: "com.apple.MobileSMS",
                runnableDebuggingMode: "1"
            )
        } else {
            // If targeting a device for a Watch App, Xcode modifies the scheme
            // to use a `RemoteRunnable`. It does this automatically though, so
            // we don't have to account for it.
            return XCScheme.BuildableProductRunnable(
                buildableReference: targetInfo.buildableReference
            )
        }
    }
}

// MARK: `askForAppToLaunch`

extension XCSchemeInfo.LaunchActionInfo {
    var askForAppToLaunch: Bool {
        return targetInfo.isWidgetKitExtension
    }
}

// MARK: `macroExpansion`

extension XCSchemeInfo.LaunchActionInfo {
    var macroExpansion: XCScheme.BuildableReference? {
        get throws {
            try targetInfo.macroExpansion
        }
    }
}

// MARK: `launcher`

extension XCSchemeInfo.LaunchActionInfo {
    var launcher: String {
        guard targetInfo.productType.canUseDebugLauncher else {
            return XCSchemeConstants.posixSpawnLauncher
        }
        return XCScheme.defaultLauncher
    }
}

// MARK: `debugger`

extension XCSchemeInfo.LaunchActionInfo {
    var debugger: String {
        guard targetInfo.productType.canUseDebugLauncher else {
            return ""
        }
        return XCScheme.defaultDebugger
    }
}

// MARK: Custom Scheme Initializer

extension XCSchemeInfo.LaunchActionInfo {
    init?(
        launchAction: XcodeScheme.LaunchAction?,
        defaultBuildConfigurationName: String,
        targetResolver: TargetResolver,
        targetIDsByLabelAndConfiguration: [String: [BazelLabel: TargetID]]
    ) throws {
        guard let launchAction = launchAction else {
          return nil
        }

        let buildConfigurationName = launchAction.buildConfigurationName ??
            defaultBuildConfigurationName

        let targetID = try targetIDsByLabelAndConfiguration.targetID(
            for: launchAction.target,
            preferredConfiguration: buildConfigurationName
        ).orThrow("""
Failed to find a `TargetID` for "\(launchAction.target)" while creating a \
`LaunchActionInfo`
""")

        try self.init(
            buildConfigurationName: buildConfigurationName,
            targetInfo: targetResolver.targetInfo(targetID: targetID),
            args: launchAction.args,
            diagnostics: XCSchemeInfo.DiagnosticsInfo(
                diagnostics: launchAction.diagnostics
            ),
            env: launchAction.env,
            workingDirectory: launchAction.workingDirectory
        )
    }
}
