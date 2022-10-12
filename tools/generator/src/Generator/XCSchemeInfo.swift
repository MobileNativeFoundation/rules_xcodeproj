import XcodeProj

struct XCSchemeInfo: Equatable {
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
        buildActionInfo: XCSchemeInfo.BuildActionInfo? = nil,
        testActionInfo: XCSchemeInfo.TestActionInfo? = nil,
        launchActionInfo: XCSchemeInfo.LaunchActionInfo? = nil,
        profileActionInfo: XCSchemeInfo.ProfileActionInfo? = nil,
        analyzeActionInfo: XCSchemeInfo.AnalyzeActionInfo? = nil,
        archiveActionInfo: XCSchemeInfo.ArchiveActionInfo? = nil,
        nameClosure: NameClosure? = nil
    ) throws {
        guard buildActionInfo != nil || testActionInfo != nil || launchActionInfo != nil else {
            let schemeName = name ?? ""
            throw PreconditionError(message: """
An `XCSchemeInfo` (\(schemeName)) should have at least one of the following: `buildActionInfo`, \
`testActionInfo`, or `launchActionInfo`.
""")
        }

        var allTargetInfos = [XCSchemeInfo.TargetInfo]()
        (buildActionInfo?.targets.map(\.targetInfo)).map { allTargetInfos.append(contentsOf: $0) }
        (testActionInfo?.targetInfos).map { allTargetInfos.append(contentsOf: $0) }
        launchActionInfo.map { allTargetInfos.append($0.targetInfo) }
        profileActionInfo.map { allTargetInfos.append($0.targetInfo) }

        let topLevelTargetInfos = Set(allTargetInfos.filter(\.pbxTarget.isTopLevel))

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
            buildConfigurationName: .defaultBuildConfigurationName
        )
        self.archiveActionInfo = archiveActionInfo ?? .init(
            buildConfigurationName: .defaultBuildConfigurationName
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
            throw PreconditionError(message: """
An `XCSchemeInfo` should have at least one of the following: `name` or `nameClosure`.
""")
        }
        self.name = schemeName
    }
}

// MARK: `allPBXTargets`

extension XCSchemeInfo {
    var allPBXTargets: Set<PBXTarget> {
        var pbxTargets = [PBXTarget]()
        if let buildActionInfo = buildActionInfo {
            pbxTargets.append(contentsOf: buildActionInfo.targets.map(\.targetInfo.pbxTarget))
        }
        if let testActionInfo = testActionInfo {
            pbxTargets.append(contentsOf: testActionInfo.targetInfos.map(\.pbxTarget))
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

// MARK: `wasCreatedForAppExtension`

extension XCSchemeInfo {
    var wasCreatedForAppExtension: Bool {
        return allPBXTargets.compactMap(\.productType).contains(where: \.isExtension)
    }
}

// MARK: Custom Scheme Initializer

extension XCSchemeInfo {
    init(
        scheme: XcodeScheme,
        targetResolver: TargetResolver,
        runnerLabel: BazelLabel,
        envs: [TargetID: [String: String]]
    ) throws {
        let targetIDsByLabel = try scheme.resolveTargetIDs(
            targetResolver: targetResolver,
            runnerLabel: runnerLabel
        )
        let schemeWithDefaults = try scheme.withDefaults
        try self.init(
            name: schemeWithDefaults.name,
            buildActionInfo: .init(
                buildAction: schemeWithDefaults.buildAction,
                targetResolver: targetResolver,
                targetIDsByLabel: targetIDsByLabel
            ),
            testActionInfo: .init(
                testAction: schemeWithDefaults.testAction,
                targetResolver: targetResolver,
                targetIDsByLabel: targetIDsByLabel,
                envs: envs
            ),
            launchActionInfo: .init(
                launchAction: schemeWithDefaults.launchAction,
                targetResolver: targetResolver,
                targetIDsByLabel: targetIDsByLabel
            ),
            profileActionInfo: .init(
                profileAction: schemeWithDefaults.profileAction,
                targetResolver: targetResolver,
                targetIDsByLabel: targetIDsByLabel
            ),
            analyzeActionInfo: .init(
                buildConfigurationName: .defaultBuildConfigurationName
            ),
            archiveActionInfo: .init(
                buildConfigurationName: .defaultBuildConfigurationName
            )
        )
    }
}
