import XcodeProj

extension XCSchemeInfo {
    struct TestActionInfo: Equatable {
        let buildConfigurationName: String
        let targetInfos: Set<XCSchemeInfo.TargetInfo>

        /// The primary initializer.
        init<TargetInfos: Sequence>(
            buildConfigurationName: String,
            targetInfos: TargetInfos
        ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
            self.buildConfigurationName = buildConfigurationName
            self.targetInfos = Set(targetInfos)

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
    init?(
        resolveHostsFor testActionInfo: XCSchemeInfo.TestActionInfo?,
        topLevelTargetInfos: [XCSchemeInfo.TargetInfo]
    ) throws {
        guard let original = testActionInfo else {
          return nil
        }
        try self.init(
            buildConfigurationName: original.buildConfigurationName,
            targetInfos: original.targetInfos.map {
                .init(resolveHostFor: $0, topLevelTargetInfos: topLevelTargetInfos)
            }
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
        try self.init(
            buildConfigurationName: testAction.buildConfigurationName,
            targetInfos: try testAction.targets.map { label in
                return try targetResolver.targetInfo(
                    targetID: try targetIDsByLabel.value(
                        for: label,
                        context: "creating a `TestActionInfo`"
                    )
                )
            }
        )
    }
}
