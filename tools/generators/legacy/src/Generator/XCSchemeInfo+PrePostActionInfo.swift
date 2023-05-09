import XcodeProj

extension XCSchemeInfo {
    struct PrePostActionInfo: Equatable {
        let name: String
        let expandVariablesBasedOn: TargetInfo?
        let script: String
    }
}

extension XCSchemeInfo.PrePostActionInfo {
    var executionAction: XCScheme.ExecutionAction {
        XCScheme.ExecutionAction(
            scriptText: script,
            title: name,
            environmentBuildable: expandVariablesBasedOn?.buildableReference
        )
    }
}

extension XCSchemeInfo.PrePostActionInfo {
    init(
        prePostAction: XcodeScheme.PrePostAction,
        buildConfigurationName: String,
        targetResolver: TargetResolver,
        targetIDsByLabelAndConfiguration: [String: [BazelLabel: TargetID]],
        context: String
    ) throws {
        guard let originalTargetLabel =
            prePostAction.expandVariablesBasedOn
        else {
            self.init(
                name: prePostAction.name,
                expandVariablesBasedOn: nil,
                script: prePostAction.script
            )
            return
        }

        let targetID = try targetIDsByLabelAndConfiguration.targetID(
            for: originalTargetLabel,
            preferredConfiguration: buildConfigurationName
        ).orThrow("""
Failed to find a `TargetID` for "\(originalTargetLabel)" while \(context)
""")

        let expandVariablesBasedOn = try targetResolver
            .targetInfo(targetID: targetID)

        self.init(
            name: prePostAction.name,
            expandVariablesBasedOn: expandVariablesBasedOn,
            script: prePostAction.script
        )
    }
}

extension Sequence where Element == XCSchemeInfo.PrePostActionInfo {
    func resolveHosts<TargetInfos: Sequence>(
        topLevelTargetInfos: TargetInfos
    ) throws -> [XCSchemeInfo.PrePostActionInfo]
    where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        map { action in
            guard let resolveHostFor = action.expandVariablesBasedOn else {
                return action
            }

            return XCSchemeInfo.PrePostActionInfo(
                name: action.name,
                expandVariablesBasedOn: .init(
                    resolveHostFor: resolveHostFor,
                    topLevelTargetInfos: topLevelTargetInfos
                ),
                script: action.script
            )
        }
    }
}
