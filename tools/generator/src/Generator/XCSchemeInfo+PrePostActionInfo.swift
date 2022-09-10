import XcodeProj

extension XCSchemeInfo {
    struct PrePostActionInfo: Equatable {
        let name: String
        let expandVariablesBasedOn: VariableExpansionContextInfo
        let script: String
    }
}

extension XCSchemeInfo.PrePostActionInfo {
    var executionAction: XCScheme.ExecutionAction {
        XCScheme.ExecutionAction(scriptText: script,
                                 title: name,
                                 environmentBuildable: expandVariablesBasedOn.targetInfo?.buildableReference)
    }
}

extension XCSchemeInfo.PrePostActionInfo {
    init(
        prePostAction: XcodeScheme.PrePostAction,
        targetResolver: TargetResolver,
        targetIDsByLabel: [BazelLabel: TargetID],
        context: String
    ) throws {
        guard let originalTargetLabel = prePostAction.expandVariablesBasedOn?.targetLabel else {
            self.init(
                name: prePostAction.name,
                expandVariablesBasedOn: .none,
                script: prePostAction.script
            )
            return
        }
        let targetID = try targetIDsByLabel.value(
            for: originalTargetLabel,
            context: context
        )
        let expandVariablesBasedOn = XCSchemeInfo.VariableExpansionContextInfo.target(
            try targetResolver.targetInfo(targetID: targetID)
        )
        self.init(name: prePostAction.name,
                  expandVariablesBasedOn: expandVariablesBasedOn,
                  script: prePostAction.script)
    }
}

extension Sequence where Element == XCSchemeInfo.PrePostActionInfo {
    func resolveHosts<TargetInfos: Sequence>(
        topLevelTargetInfos: TargetInfos
    ) throws -> [XCSchemeInfo.PrePostActionInfo] where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        try map { action in
            XCSchemeInfo.PrePostActionInfo(
                name: action.name,
                expandVariablesBasedOn: try .init(
                    resolveHostsFor: action.expandVariablesBasedOn,
                    topLevelTargetInfos: topLevelTargetInfos
                ),
                script: action.script
            )
        }
    }
}
