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
        guard buildActionInfo != nil || testActionInfo != nil || launchActionInfo != nil else {
            throw PreconditionError(message: """
An `XCSchemeInfo` (\(name)) should have at least one of the following: `buildActionInfo`, \
`testActionInfo`, `launchActionInfo`.
""")
        }

        var topLevelTargetInfos = [XCSchemeInfo.TargetInfo]()
        if let testActionInfo = testActionInfo {
            topLevelTargetInfos += testActionInfo.targetInfos
        }
        if let launchActionInfo = launchActionInfo {
            topLevelTargetInfos.append(launchActionInfo.targetInfo)
        }

        self.name = name
        self.buildActionInfo = try .init(
            resolveHostsFor: buildActionInfo,
            topLevelTargetInfos: topLevelTargetInfos
        )
        self.testActionInfo = try .init(
            resolveHostsFor: testActionInfo,
            topLevelTargetInfos: topLevelTargetInfos
        )
        self.launchActionInfo = try .init(
            resolveHostsFor: launchActionInfo,
            topLevelTargetInfos: topLevelTargetInfos
        )
        self.profileActionInfo = .init(
            resolveHostsFor: profileActionInfo,
            topLevelTargetInfos: topLevelTargetInfos
        )
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

        /// Create a copy of the build action info with host in the target infos resolved
        init?(
            resolveHostsFor buildActionInfo: XCSchemeInfo.BuildActionInfo?,
            topLevelTargetInfos: [XCSchemeInfo.TargetInfo]
        ) throws {
            guard let original = buildActionInfo else {
                return nil
            }
            try self.init(
                targetInfos: original.targetInfos.map {
                    .init(resolveHostFor: $0, topLevelTargetInfos: topLevelTargetInfos)
                }
            )
        }
    }
}

// MARK: XCSchemeInfo.TestActionInfo

extension XCSchemeInfo {
    struct TestActionInfo {
        let buildConfigurationName: String
        let targetInfos: [XCSchemeInfo.TargetInfo]

        /// The primary initializer.
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

        /// Create a copy of the test action info with host in the target infos resolved
        init?(
            resolveHostsFor testActionInfo: XCSchemeInfo.TestActionInfo?,
            topLevelTargetInfos: [XCSchemeInfo.TargetInfo]
        ) throws {
            guard let original = testActionInfo else {
              return nil
            }
            try self.init(
                buildConfigurationName: original.buildConfigurationName,
                targetInfos: original.targetInfos.map {
                    .init(resolveHostFor: $0, topLevelTargetInfos: topLevelTargetInfos)
                }
            )
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
}

// MARK: XCSchemeInfo.ProfileActionInfo

extension XCSchemeInfo {
    struct ProfileActionInfo {
        let buildConfigurationName: String
        let targetInfo: XCSchemeInfo.TargetInfo
    }
}

extension XCSchemeInfo.ProfileActionInfo {
    /// Create a copy of the profile action info with host in the target info resolved.
    init?(
        resolveHostsFor profileActionInfo: XCSchemeInfo.ProfileActionInfo?,
        topLevelTargetInfos: [XCSchemeInfo.TargetInfo]
    ) {
        guard let original = profileActionInfo else {
          return nil
        }
        self.init(
            buildConfigurationName: original.buildConfigurationName,
            targetInfo: .init(
                resolveHostFor: original.targetInfo,
                topLevelTargetInfos: topLevelTargetInfos
            )
        )
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
    var allPBXTargets: Set<PBXTarget> {
        var pbxTargets = [PBXTarget]()
        if let buildActionInfo = buildActionInfo {
            pbxTargets += buildActionInfo.targetInfos.map(\.pbxTarget)
        }
        if let testActionInfo = testActionInfo {
            pbxTargets += testActionInfo.targetInfos.map(\.pbxTarget)
        }
        if let launchActionInfo = launchActionInfo {
            pbxTargets.append(launchActionInfo.targetInfo.pbxTarget)
        }
        if let profileActionInfo = profileActionInfo {
            pbxTargets.append(profileActionInfo.targetInfo.pbxTarget)
        }
        return .init(pbxTargets)
    }

    var wasCreatedForAppExtension: Bool {
        return allPBXTargets.compactMap(\.productType).anySatisfy(\.isExtension)
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
            !targetInfo.productType.isWatchApplication
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
