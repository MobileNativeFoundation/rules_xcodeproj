import XcodeProj

extension XCSchemeInfo {
    struct PrePostAction: Equatable {
        let name: String
        let target: TargetInfo
        let scriptContents: String
    }
    
    struct BuildActionInfo: Equatable {
        let targets: Set<XCSchemeInfo.BuildTargetInfo>
        let preActions: [PrePostAction]
        let postActions: [PrePostAction]
        
        init<BuildTargetInfos: Sequence>(
            targets: BuildTargetInfos,
            preActions: [PrePostAction] = [],
            postActions: [PrePostAction] = []
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
        
        let prePostActionsMapper = { (actions: [XCSchemeInfo.PrePostAction]) -> [XCSchemeInfo.PrePostAction]  in
            return actions.map { action in
                    .init(name: action.name,
                          target: .init(
                            resolveHostFor: action.target,
                            topLevelTargetInfos: topLevelTargetInfos
                          ), scriptContents: action.scriptContents)
            }
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
            preActions: prePostActionsMapper(original.preActions),
            postActions: prePostActionsMapper(original.postActions)
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
        let prePostActionsMapper = { (actions: [XcodeScheme.PrePostAction]) throws -> [XCSchemeInfo.PrePostAction] in
            try actions.map { action in
                let targetID = try targetIDsByLabel.value(
                    for: action.target,
                    context: "creating a `BuildActionInfo`"
                )
                return .init(name: action.name,
                             target: try targetResolver.targetInfo(targetID: targetID),
                             scriptContents: action.scriptContents)
            }
        }
        try self.init(targets: buildTargetInfos,
                      preActions: try prePostActionsMapper(buildAction.preActions),
                      postActions: try prePostActionsMapper(buildAction.postActions))
    }
}

extension XCSchemeInfo.PrePostAction {
    var executionAction: XCScheme.ExecutionAction {
        XCScheme.ExecutionAction(scriptText: scriptContents,
                                 title: name,
                                 environmentBuildable: target.buildableReference)
    }
}
