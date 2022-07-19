import XcodeProj

extension XCSchemeInfo {
    struct TestActionInfo {
        let buildConfigurationName: String
        let targetInfos: [XCSchemeInfo.TargetInfo]

        /// The primary initializer.
        init<TargetInfos: Sequence>(
            buildConfigurationName: String,
            targetInfos: TargetInfos
        ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
            self.buildConfigurationName = buildConfigurationName
            self.targetInfos = Array(targetInfos)

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
}
