import XcodeProj

extension XCSchemeInfo {
    struct PrePostActionInfo: Equatable {
        let name: String
        let targetInfo: TargetInfo?
        let script: String
    }
}

extension XCSchemeInfo.PrePostActionInfo {
    var executionAction: XCScheme.ExecutionAction {
        XCScheme.ExecutionAction(scriptText: script,
                                 title: name,
                                 environmentBuildable: targetInfo?.buildableReference)
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
                targetInfo: nil,
                script: prePostAction.script
            )
            return
        }
        let targetID = try targetIDsByLabel.value(
            for: originalTargetLabel,
            context: context
        )
        self.init(name: prePostAction.name,
                  targetInfo: try targetResolver.targetInfo(targetID: targetID),
                  script: prePostAction.script)
    }
}

extension Sequence where Element == XCSchemeInfo.PrePostActionInfo {
    func resolveHosts<TargetInfos: Sequence>(
        topLevelTargetInfos: TargetInfos
    ) throws -> [XCSchemeInfo.PrePostActionInfo] where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        map { action in
            XCSchemeInfo.PrePostActionInfo(
                name: action.name,
                targetInfo: action.targetInfo.map { target in
                        .init(
                            resolveHostFor: target,
                            topLevelTargetInfos: topLevelTargetInfos
                        )
                },
                script: action.script
            )
        }
    }
}
