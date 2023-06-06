import GeneratorCommon
import OrderedCollections
import XcodeProj

extension XCSchemeInfo {
    struct BuildActionInfo: Equatable {
        let targets: Set<XCSchemeInfo.BuildTargetInfo>
        let preActions: [PrePostActionInfo]
        let postActions: [PrePostActionInfo]

        init<BuildTargetInfos: Sequence>(
            targets: BuildTargetInfos,
            preActions: [PrePostActionInfo] = [],
            postActions: [PrePostActionInfo] = []
        ) throws where BuildTargetInfos.Element == XCSchemeInfo.BuildTargetInfo {
            self.targets = Set(targets)
            self.preActions = preActions
            self.postActions = postActions
            guard !self.targets.isEmpty else {
                throw PreconditionError(message: """
An `XCSchemeInfo.BuildActionInfo` should have at least one `XCSchemeInfo.BuildTargetInfo`.
""")
            }
        }
    }
}

// MARK: Host Resolution Initializer

extension XCSchemeInfo.BuildActionInfo {
    /// Create a copy of the `BuildActionInfo` with the host in `TargetInfo` values resolved.
    init?<TargetInfos: Sequence>(
        resolveHostsFor buildActionInfo: XCSchemeInfo.BuildActionInfo?,
        topLevelTargetInfos: TargetInfos
    ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        guard let original = buildActionInfo else {
            return nil
        }

        try self.init(
            targets: original.targets.map { buildTarget in
                .init(
                    targetInfo: .init(
                        resolveHostFor: buildTarget.targetInfo,
                        topLevelTargetInfos: topLevelTargetInfos
                    ),
                    buildFor: buildTarget.buildFor
                )
            },
            preActions: original.preActions
                .resolveHosts(topLevelTargetInfos: topLevelTargetInfos),
            postActions: original.postActions
                .resolveHosts(topLevelTargetInfos: topLevelTargetInfos)
        )
    }
}

// MARK: Custom Scheme Initializer

extension XCSchemeInfo.BuildActionInfo {
    init?(
        buildAction: XcodeScheme.BuildAction?,
        launchActionInfo: XCSchemeInfo.LaunchActionInfo?,
        testActionInfo: XCSchemeInfo.TestActionInfo?,
        profileActionInfo: XCSchemeInfo.ProfileActionInfo?,
        defaultBuildConfigurationName: String,
        targetResolver: TargetResolver,
        targetIDsByLabelAndConfiguration: [String: [BazelLabel: TargetID]]
    ) throws {
        guard let buildAction = buildAction else {
            return nil
        }

        var otherActionTargetInfos: OrderedSet<XCSchemeInfo.TargetInfo> = []
        var preferredConfigurations: OrderedSet<String> = []
        if let launchActionInfo {
            otherActionTargetInfos.append(launchActionInfo.targetInfo)
            preferredConfigurations
                .append(launchActionInfo.buildConfigurationName)
        }
        if let testActionInfo {
            otherActionTargetInfos
                .append(contentsOf: testActionInfo.targetInfos)
            preferredConfigurations
                .append(testActionInfo.buildConfigurationName)
        }
        preferredConfigurations.append(defaultBuildConfigurationName)
        if let profileActionInfo {
            otherActionTargetInfos.append(profileActionInfo.targetInfo)
            preferredConfigurations
                .append(profileActionInfo.buildConfigurationName)
        }

        let buildTargetInfos: [XCSchemeInfo.BuildTargetInfo] = try buildAction
            .targets
            .map { buildTarget in
                let targetInfo: XCSchemeInfo.TargetInfo
                if let otherActionTargetInfo = otherActionTargetInfos
                    .first(where: { $0.label == buildTarget.label })
                {
                    targetInfo = otherActionTargetInfo
                } else {
                    let targetID = try targetIDsByLabelAndConfiguration
                        .targetID(
                            for: buildTarget.label,
                            preferredConfigurations: preferredConfigurations
                        ).orThrow("""
Failed to find a `TargetID` for "\(buildTarget.label)" while creating a \
`BuildActionInfo`
""")
                    targetInfo = try targetResolver.targetInfo(
                        targetID: targetID
                    )
                }
                return XCSchemeInfo.BuildTargetInfo(
                    targetInfo: targetInfo,
                    buildFor: buildTarget.buildFor
                )
            }

        try self.init(
            targets: buildTargetInfos,
            preActions: buildAction.preActions.prePostActionInfos(
                preferredConfigurations: preferredConfigurations,
                targetResolver: targetResolver,
                targetIDsByLabelAndConfiguration:
                    targetIDsByLabelAndConfiguration,
                context: "creating a pre-action `PrePostActionInfo`"
            ),
            postActions: buildAction.postActions.prePostActionInfos(
                preferredConfigurations: preferredConfigurations,
                targetResolver: targetResolver,
                targetIDsByLabelAndConfiguration:
                    targetIDsByLabelAndConfiguration,
                context: "creating a post-action `PrePostActionInfo`"
            )
        )
    }
}

extension XCSchemeInfo.BuildActionInfo {
    var launchableTargets: Set<XCSchemeInfo.BuildTargetInfo> {
        targets.filter(\.targetInfo.productType.isLaunchable)
    }
}
