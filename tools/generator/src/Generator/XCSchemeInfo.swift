import XcodeProj

struct XCSchemeInfo {
    let name: String
    let buildActionInfo: XCSchemeInfo.BuildActionInfo?
    let testActionInfo: XCSchemeInfo.TestActionInfo?
    let launchActionInfo: XCSchemeInfo.LaunchActionInfo?
    let profileActionInfo: XCSchemeInfo.ProfileActionInfo?
    let analyzeActionInfo: XCSchemeInfo.AnalyzeActionInfo
    let archiveActionInfo: XCSchemeInfo.ArchiveActionInfo

    typealias NameClosure = (
        XCSchemeInfo.BuildActionInfo?,
        XCSchemeInfo.TestActionInfo?,
        XCSchemeInfo.LaunchActionInfo?,
        XCSchemeInfo.ProfileActionInfo?
    ) throws -> String

    init(
        name: String? = nil,
        nameClosure: NameClosure? = nil,
        buildActionInfo: XCSchemeInfo.BuildActionInfo? = nil,
        testActionInfo: XCSchemeInfo.TestActionInfo? = nil,
        launchActionInfo: XCSchemeInfo.LaunchActionInfo? = nil,
        profileActionInfo: XCSchemeInfo.ProfileActionInfo? = nil,
        analyzeActionInfo: XCSchemeInfo.AnalyzeActionInfo? = nil,
        archiveActionInfo: XCSchemeInfo.ArchiveActionInfo? = nil
    ) throws {
        guard buildActionInfo != nil || testActionInfo != nil || launchActionInfo != nil else {
            let schemeName = name ?? ""
            throw PreconditionError(message: """
An `XCSchemeInfo` (\(schemeName)) should have at least one of the following: `buildActionInfo`, \
`testActionInfo`, `launchActionInfo`.
""")
        }

        guard name != nil || nameClosure != nil else {
            throw PreconditionError(message: """
An `XCSchemeInfo` should have at least one of the following: `name`, `nameClosure`.
""")
        }

        var topLevelTargetInfos = [XCSchemeInfo.TargetInfo]()
        if let testActionInfo = testActionInfo {
            topLevelTargetInfos += testActionInfo.targetInfos
        }
        if let launchActionInfo = launchActionInfo {
            topLevelTargetInfos.append(launchActionInfo.targetInfo)
        }

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

        let schemeName: String
        if let name = name {
            schemeName = name
        } else if let nameClosure = nameClosure {
            schemeName = try nameClosure(
                self.buildActionInfo,
                self.testActionInfo,
                self.launchActionInfo,
                self.profileActionInfo
            )
        } else {
            // This should never happen as we check to ensure that the client gave us a name or a
            // name closure.
            schemeName = ""
        }
        self.name = schemeName
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
