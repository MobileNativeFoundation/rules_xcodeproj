import XcodeProj

extension XCSchemeInfo {
    struct PrePostActionInfo: Equatable {
        let name: String
        let target: TargetInfo
        let script: String
    }
}

extension XCSchemeInfo.PrePostActionInfo {
    var executionAction: XCScheme.ExecutionAction {
        XCScheme.ExecutionAction(scriptText: script,
                                 title: name,
                                 environmentBuildable: target.buildableReference)
    }
}

extension XCSchemeInfo.PrePostActionInfo {
    init(
        prePostAction: XcodeScheme.PrePostAction,
        targetResolver: TargetResolver,
        targetIDsByLabel: [BazelLabel: TargetID],
        context: String
    ) throws {
        let targetID = try targetIDsByLabel.value(
            for: prePostAction.target,
            context: context
        )
        self.init(name: prePostAction.name,
                  target: try targetResolver.targetInfo(targetID: targetID),
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
                target: .init(
                    resolveHostFor: action.target,
                    topLevelTargetInfos: topLevelTargetInfos
                ),
                script: action.script)
        }
    }
}
