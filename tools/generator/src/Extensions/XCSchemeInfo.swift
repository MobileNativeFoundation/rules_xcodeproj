import XcodeProj

struct XCSchemeInfo {
    let name: String
    let buildActionInfo: XCSchemeInfo.BuildActionInfo?
    let testActionInfo: XCSchemeInfo.TestActionInfo?
    let launchActionInfo: XCSchemeInfo.LaunchActionInfo?
    let profileActionInfo: XCSchemeInfo.ProfileActionInfo?
    let analyzeActionInfo: XCSchemeInfo.AnalyzeActionInfo
    let archiveActionInfo: XCSchemeInfo.ArchiveActionInfo

    init(
        name: String,
        buildActionInfo: XCSchemeInfo.BuildActionInfo? = nil,
        testActionInfo: XCSchemeInfo.TestActionInfo? = nil,
        launchActionInfo: XCSchemeInfo.LaunchActionInfo? = nil,
        profileActionInfo: XCSchemeInfo.ProfileActionInfo? = nil,
        analyzeActionInfo: XCSchemeInfo.AnalyzeActionInfo? = nil,
        archiveActionInfo: XCSchemeInfo.ArchiveActionInfo? = nil
    ) throws {
        guard buildActionInfo != nil, testActionInfo != nil, launchActionInfo != nil else {
            throw PreconditionError(message: """
An `XCSchemeInfo` should have at a `buildActionInfo`, a `testActionInfo`, or a `launchActionInfo`.
""")
        }

        self.name = name
        self.buildActionInfo = buildActionInfo
        self.testActionInfo = testActionInfo
        self.launchActionInfo = launchActionInfo
        self.profileActionInfo = profileActionInfo
        self.analyzeActionInfo = analyzeActionInfo ?? .init(
            buildConfigurationName: XCSchemeConstants.defaultBuildConfigurationName
        )
        self.archiveActionInfo = archiveActionInfo ?? .init(
            buildConfigurationName: XCSchemeConstants.defaultBuildConfigurationName
        )
    }
}

// MARK: XCSchemeInfo.BuildActionInfo

extension XCSchemeInfo {
    struct BuildActionInfo {
        let targetInfos: [XCSchemeInfo.TargetInfo]

        init<TargetInfos: Sequence>(
            targetInfos: TargetInfos
        ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
            self.targetInfos = Array(targetInfos)

            guard !self.targetInfos.isEmpty else {
                throw PreconditionError(message: """
An `XCSchemeInfo.BuildActionInfo` should have at least one `XCSchemeInfo.TargetInfo`.
""")
            }
        }
    }
}

// MARK: XCSchemeInfo.TestActionInfo

extension XCSchemeInfo {
    struct TestActionInfo {
        let buildConfigurationName: String
        let targetInfos: [XCSchemeInfo.TargetInfo]

        init<TargetInfos: Sequence>(
            buildConfigurationName: String,
            targetInfos: TargetInfos
        ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
            self.buildConfigurationName = buildConfigurationName
            self.targetInfos = Array(targetInfos)

            guard !self.targetInfos.isEmpty else {
                throw PreconditionError(message: """
An `XCSchemeInfo.TestActionInfo` should have at least one `XCSchemeInfo.TargetInfo`.
""")
            }
            guard self.targetInfos.allSatisfy(\.pbxTarget.isTestable) else {
                throw PreconditionError(message: """
An `XCSchemeInfo.TestActionInfo` should only contain testable `XCSchemeInfo.TargetInfo` values.
""")
            }
        }
    }
}

// MARK: XCSchemeInfo.LaunchActionInfo

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

// MARK: XCSchemeInfo.ProfileActionInfo

extension XCSchemeInfo {
    struct ProfileActionInfo {
        let buildConfigurationName: String
        let targetInfo: XCSchemeInfo.TargetInfo
    }
}

// MARK: XCSchemeInfo.AnalyzeActionInfo

extension XCSchemeInfo {
    struct AnalyzeActionInfo {
        let buildConfigurationName: String
    }
}

// MARK: XCSchemeInfo.AnalyzeActionInfo

extension XCSchemeInfo {
    struct ArchiveActionInfo {
        let buildConfigurationName: String
    }
}

// MARK: XCSchemeInfo Extensions

extension XCSchemeInfo {
    var wasCreatedForAppExtension: Bool {
        // TODO(chuck): Implement by looking at all of producTypes in the scheme. If any are
        // isExtension, then true.
        // wasCreatedForAppExtension: productType.isExtension ? true : nil
        return false
    }
}

// MARK: XCSchemeInfo.LaunchActionInfo Extensions

extension XCSchemeInfo.LaunchActionInfo {
    var runnable: XCScheme.Runnable {
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

    var askForAppToLaunch: Bool {
        return targetInfo.isWidgetKitExtension
    }

    var macroExpansion: XCScheme.BuildableReference? {
        // TODO(chuck): Update the host selection code.
        if let hostBuildableReference = targetInfo.hostInfos.first?.buildableReference,
            targetInfo.productType.isWatchApplication
        {
            return hostBuildableReference
        } else if targetInfo.pbxTarget.isTestable {
            return targetInfo.buildableReference
        }
        return nil
    }

    var launcher: String {
        if targetInfo.productType.canUseDebugLauncher {
            return XCScheme.defaultLauncher
        }
        return "Xcode.IDEFoundation.Launcher.PosixSpawn"
    }

    var debugger: String {
        if targetInfo.productType.canUseDebugLauncher {
            return XCScheme.defaultDebugger
        }
        return ""
    }
}

extension XCSchemeInfo.ProfileActionInfo {
    var runnable: XCScheme.BuildableProductRunnable {
        return .init(buildableReference: targetInfo.buildableReference)
    }
}
