import XcodeProj

extension XCSchemeInfo {
    struct BuildActionInfo: Equatable {
        let targetInfos: Set<XCSchemeInfo.TargetInfo>

        init<TargetInfos: Sequence>(
            targetInfos: TargetInfos
        ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
            self.targetInfos = Set(targetInfos)

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
    /// Create a copy of the `BuildActionInfo` with the host in `TargetInfo` values resolved.
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
        try self.init(
            targetInfos: try buildAction.targets.map { label in
                return try targetResolver.targetInfo(
                    targetID: try targetIDsByLabel.value(
                        for: label,
                        context: "creating a `BuildActionInfo`"
                    )
                )
            }
        )
    }
}
