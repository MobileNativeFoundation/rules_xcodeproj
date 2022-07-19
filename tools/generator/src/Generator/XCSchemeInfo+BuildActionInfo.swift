import XcodeProj

extension XCSchemeInfo {
    struct BuildActionInfo {
        let targetInfos: [XCSchemeInfo.TargetInfo]

        init<TargetInfos: Sequence>(
            targetInfos: TargetInfos
        ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
            self.targetInfos = Array(targetInfos)

            guard !self.targetInfos.isEmpty else {
                throw PreconditionError(message: """
An `XCSchemeInfo.BuildActionInfo` should have at least one `XCSchemeInfo.TargetInfo`.
""")
            }
        }
    }
}

// MARK: Host Resolution Initializer

extension XCSchemeInfo.BuildActionInfo {
    /// Create a copy of the build action info with host in the target infos resolved
    init?(
        resolveHostsFor buildActionInfo: XCSchemeInfo.BuildActionInfo?,
        topLevelTargetInfos: [XCSchemeInfo.TargetInfo]
    ) throws {
        guard let original = buildActionInfo else {
            return nil
        }
        try self.init(
            targetInfos: original.targetInfos.map {
                .init(resolveHostFor: $0, topLevelTargetInfos: topLevelTargetInfos)
            }
        )
    }
}
