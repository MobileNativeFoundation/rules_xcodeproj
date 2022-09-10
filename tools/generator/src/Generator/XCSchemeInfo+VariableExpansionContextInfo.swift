extension XCSchemeInfo {
    enum VariableExpansionContextInfo: Equatable {
        case none
        case target(TargetInfo)
    }
}

extension XCSchemeInfo.VariableExpansionContextInfo {
    var targetInfo: XCSchemeInfo.TargetInfo? {
        guard case let .target(targetInfo) = self else {
            return nil
        }
        return targetInfo
    }
}

// MARK: Host Resolution Initializer

extension XCSchemeInfo.VariableExpansionContextInfo {
    init<TargetInfos: Sequence>(
        resolveHostsFor original: XCSchemeInfo.VariableExpansionContextInfo,
        topLevelTargetInfos: TargetInfos
    ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        switch original {
        case .none:
            self = .none
        case let .target(targetInfo):
            self = .target(
                .init(resolveHostFor: targetInfo, topLevelTargetInfos: topLevelTargetInfos)
            )
        }
    }
}

// MARK: Custom Scheme Initializer

extension XCSchemeInfo.VariableExpansionContextInfo {
    init(
        context: XcodeScheme.VariableExpansionContext,
        targetResolver: TargetResolver,
        targetIDsByLabel: [BazelLabel: TargetID]
    ) throws {
        switch context {
        case .none:
            self = .none
        case let .target(label):
            self = .target(
                try targetResolver.targetInfo(
                    targetID: try targetIDsByLabel.value(
                        for: label,
                        context: "creating a `VariableExpansionContextInfo`"
                    )
                )
            )
        }
    }
}
