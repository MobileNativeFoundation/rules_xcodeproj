import XcodeProj

extension XCSchemeInfo {
    struct BuildActionInfo: Equatable {
        let targets: Set<XCSchemeInfo.BuildTarget>

        init<BuildTargets: Sequence>(
            targets: BuildTargets
        ) throws where BuildTargets.Element == XCSchemeInfo.BuildTarget {
            self.targets = Set(targets)

            guard !self.targets.isEmpty else {
                throw PreconditionError(message: """
An `XCSchemeInfo.BuildActionInfo` should have at least one `XCSchemeInfo.BuildTarget`.
""")
            }
        }
    }
}

// MARK: Host Resolution Initializer

extension XCSchemeInfo.BuildActionInfo {
    /// Create a copy of the `BuildActionInfo` with the host in `TargetInfo` values resolved.
    init?<TargetInfos: Sequence>(
        resolveHostsFor buildActionInfo: XCSchemeInfo.BuildActionInfo?,
        topLevelTargetInfos: TargetInfos
    ) throws where TargetInfos.Element == XCSchemeInfo.TargetInfo {
        guard let original = buildActionInfo else {
            return nil
        }
        try self.init(
            targets: original.targets.map { buildTarget in
                .init(
                    targetInfo: .init(
                        resolveHostFor: buildTarget.targetInfo,
                        topLevelTargetInfos: topLevelTargetInfos
                    ),
                    buildFor: buildTarget.buildFor
                )
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
        let targetInfos = try buildAction.targets.map { label in
            return try targetResolver.targetInfo(
                targetID: try targetIDsByLabel.value(
                    for: label,
                    context: "creating a `BuildActionInfo`"
                )
            )
        }
        // GH573: Map buildFor from XcodeScheme to XCSchemeInfo here.
        try self.init(
            targets: targetInfos.map {
                .init(targetInfo: $0)
            }
        )
    }
}
