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
            preActions: try original.preActions
                .resolveHosts(topLevelTargetInfos: topLevelTargetInfos),
            postActions: try original.postActions
                .resolveHosts(topLevelTargetInfos: topLevelTargetInfos)
        )
    }
}

// MARK: Custom Scheme Initializer

extension XCSchemeInfo.BuildActionInfo {
    init?(
        buildAction: XcodeScheme.BuildAction?,
        targetResolver: TargetResolver,
        targetIDsByLabel: [BazelLabel: TargetID]
    ) throws {
        guard let buildAction = buildAction else {
            return nil
        }
        let buildTargetInfos: [XCSchemeInfo.BuildTargetInfo] = try buildAction.targets
            .map { buildTarget in
                let targetID = try targetIDsByLabel.value(
                    for: buildTarget.label,
                    context: "creating a `BuildActionInfo`"
                )
                return XCSchemeInfo.BuildTargetInfo(
                    targetInfo: try targetResolver.targetInfo(targetID: targetID),
                    buildFor: buildTarget.buildFor
                )
            }

        try self.init(
            targets: buildTargetInfos,
            preActions: buildAction.preActions.prePostActionInfos(
                targetResolver: targetResolver,
                targetIDsByLabel: targetIDsByLabel,
                context: "creating a pre-action `PrePostActionInfo`"
            ),
            postActions: buildAction.postActions.prePostActionInfos(
                targetResolver: targetResolver,
                targetIDsByLabel: targetIDsByLabel,
                context: "creating a post-action `PrePostActionInfo`"
            )
        )
    }
}

extension XCSchemeInfo.BuildActionInfo {
    var launchableTargets: Set<XCSchemeInfo.BuildTargetInfo> {
        targets.filter { $0.targetInfo.productType.isLaunchable }
    }
}
