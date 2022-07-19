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

// MARK: allPBXTargets

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
}

// MARK: wasCreatedForAppExtension

extension XCSchemeInfo {
    var wasCreatedForAppExtension: Bool {
        return allPBXTargets.compactMap(\.productType).anySatisfy(\.isExtension)
    }
}
