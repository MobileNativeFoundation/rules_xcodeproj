import XcodeProj

extension XCSchemeInfo {
    struct LaunchActionInfo {
        let buildConfigurationName: String
        let targetInfo: XCSchemeInfo.TargetInfo
        let args: [String]
        let env: [String: String]
        let workingDirectory: String?

        init(
            buildConfigurationName: String,
            targetInfo: XCSchemeInfo.TargetInfo,
            args: [String] = [],
            env: [String: String] = [:],
            workingDirectory: String? = nil
        ) throws {
            guard targetInfo.productType.isLaunchable else {
                throw PreconditionError(message: """
An `XCSchemeInfo.LaunchActionInfo` should have a launchable `XCSchemeInfo.TargetInfo` value.
""")
            }
            self.buildConfigurationName = buildConfigurationName
            self.targetInfo = targetInfo
            self.args = args
            self.env = env
            self.workingDirectory = workingDirectory
        }
    }
}

// MARK: Host Resolution Initializer

extension XCSchemeInfo.LaunchActionInfo {
    /// Create a copy of the launch action info with host in the target info resolved.
    init?(
        resolveHostsFor launchActionInfo: XCSchemeInfo.LaunchActionInfo?,
        topLevelTargetInfos: [XCSchemeInfo.TargetInfo]
    ) throws {
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
            env: original.env,
            workingDirectory: original.workingDirectory
        )
    }
}

// MARK: `runnable`

extension XCSchemeInfo.LaunchActionInfo {
    var runnable: XCScheme.Runnable? {
        // To produce a similar result to the current generation code, we need to have a
        // LaunchActionInfo, but we do not want to set the runnable.
        if targetInfo.pbxTarget.isTestable {
            return nil
        }
        if targetInfo.isWidgetKitExtension {
            return XCScheme.RemoteRunnable(
                buildableReference: targetInfo.buildableReference,
                bundleIdentifier: "com.apple.springboard",
                runnableDebuggingMode: "2"
            )
        } else {
            // If targeting a device for a Watch App, Xcode modifies the scheme
            // to use a `RemoteRunnable`. It does this automatically though, so
            // we don't have to account for it
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
            if let hostBuildableReference = try targetInfo.selectedHostInfo?.buildableReference,
                !targetInfo.productType.isWatchApplication
            {
                return hostBuildableReference
            } else if targetInfo.pbxTarget.isTestable {
                return targetInfo.buildableReference
            }
            return nil
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
