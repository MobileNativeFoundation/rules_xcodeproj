import XcodeProj

extension XCSchemeInfo {
    enum VariableExpansionContextInfo: Equatable {
        case none
        case target(TargetInfo)
    }
}

extension XCSchemeInfo {
    struct TestActionInfo: Equatable {
        let buildConfigurationName: String
        let targetInfos: Set<XCSchemeInfo.TargetInfo>
        let args: [String]
        let env: [String: String]
        let expandVariablesBasedOn: VariableExpansionContextInfo

        /// The primary initializer.
        init<TargetInfos: Sequence>(
            buildConfigurationName: String,
            targetInfos: TargetInfos,
            args: [String] = [],
            env: [String: String] = [:],
            expandVariablesBasedOn: XCSchemeInfo.VariableExpansionContextInfo = .none
        ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
            self.buildConfigurationName = buildConfigurationName
            self.targetInfos = Set(targetInfos)
            self.args = args
            self.env = env
            self.expandVariablesBasedOn = expandVariablesBasedOn

            guard !self.targetInfos.isEmpty else {
                throw PreconditionError(message: """
An `XCSchemeInfo.TestActionInfo` should have at least one `XCSchemeInfo.TargetInfo`.
""")
            }
            guard self.targetInfos.allSatisfy(\.pbxTarget.isTestable) else {
                throw PreconditionError(message: """
An `XCSchemeInfo.TestActionInfo` should only contain testable `XCSchemeInfo.TargetInfo` values.
""")
            }
        }
    }
}

// MARK: Host Resolution Initializer

extension XCSchemeInfo.TestActionInfo {
    /// Create a copy of the test action info with host in the target infos resolved
    init?<TargetInfos: Sequence>(
        resolveHostsFor testActionInfo: XCSchemeInfo.TestActionInfo?,
        topLevelTargetInfos: TargetInfos
    ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        guard let original = testActionInfo else {
          return nil
        }

        let expandVariablesBasedOn: XCSchemeInfo.VariableExpansionContextInfo
        switch original.expandVariablesBasedOn {
        case .none:
            expandVariablesBasedOn = .none
        case let .target(targetInfo):
            expandVariablesBasedOn = .target(
                .init(resolveHostFor: targetInfo, topLevelTargetInfos: topLevelTargetInfos)
            )
        }

        try self.init(
            buildConfigurationName: original.buildConfigurationName,
            targetInfos: original.targetInfos.map {
                .init(resolveHostFor: $0, topLevelTargetInfos: topLevelTargetInfos)
            },
            args: original.args,
            env: original.env,
            expandVariablesBasedOn: expandVariablesBasedOn
        )
    }
}

// MARK: Custom Scheme Initializer

extension XCSchemeInfo.TestActionInfo {
    init?(
        testAction: XcodeScheme.TestAction?,
        targetResolver: TargetResolver,
        targetIDsByLabel: [BazelLabel: TargetID]
    ) throws {
        guard let testAction = testAction else {
          return nil
        }

        let expandVariablesBasedOn: XCSchemeInfo.VariableExpansionContextInfo
        switch testAction.expandVariablesBasedOn {
        case .none:
            expandVariablesBasedOn = .none
        case let .target(label):
            expandVariablesBasedOn = .target(
                try targetResolver.targetInfo(
                    targetID: try targetIDsByLabel.value(
                        for: label,
                        context: "creating a `TestActionInfo`"
                    )
                )
            )
        }

        try self.init(
            buildConfigurationName: testAction.buildConfigurationName,
            targetInfos: try testAction.targets.map { label in
                return try targetResolver.targetInfo(
                    targetID: try targetIDsByLabel.value(
                        for: label,
                        context: "creating a `TestActionInfo`"
                    )
                )
            },
            args: testAction.args,
            env: testAction.env,
            expandVariablesBasedOn: expandVariablesBasedOn
        )
    }
}
