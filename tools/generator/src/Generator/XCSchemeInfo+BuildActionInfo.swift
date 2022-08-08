import XcodeProj

extension XCSchemeInfo {
    struct BuildActionInfo: Equatable {
        let targets: Set<XCSchemeInfo.BuildTargetInfo>

        init<BuildTargetInfos: Sequence>(
            targets: BuildTargetInfos
        ) throws where BuildTargetInfos.Element == XCSchemeInfo.BuildTargetInfo {
            self.targets = Set(targets)

            guard !self.targets.isEmpty else {
                throw PreconditionError(message: """
An `XCSchemeInfo.BuildActionInfo` should have at least one `XCSchemeInfo.BuildTargetInfo`.
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
    init(
        scheme: XcodeScheme,
        targetResolver: TargetResolver,
        targetIDsByLabel: [BazelLabel: TargetID]
    ) throws {
        let context = "creating a `BuildActionInfo`"
        var buildTargetInfos = [BazelLabel: XCSchemeInfo.BuildTarget]()

        // func getBuildTargetInfo(
        //     _ label: BazelLabel,
        //     defaultBuildFor: @autoclosure () -> XCSchemeInfo.BuildFor
        // ) throws -> XCSchemeInfo.BuildTarget {
        //     return buildTargetInfos[label, default: .init(
        //         targetInfo: try targetResolver.targetInfo(
        //             targetID: try targetIDsByLabel.value(for: label, context: context)
        //         ),
        //         buildFor: defaultBuildFor()
        //     )]
        // }

        func getBuildTargetInfo(
            _ label: BazelLabel,
            defaultBuildFor: @autoclosure () -> XCSchemeInfo.BuildFor
        ) throws -> XCSchemeInfo.BuildTarget {
            if let existing = buildTargetInfos[label] {
                return existing
            }
            return .init(
                targetInfo: try targetResolver.targetInfo(
                    targetID: try targetIDsByLabel.value(for: label, context: context)
                ),
                buildFor: defaultBuildFor()
            )
        }

        func enableBuildForValue(
            _ label: BazelLabel,
            _ keyPath: WritableKeyPath<XCSchemeInfo.BuildFor, XCSchemeInfo.BuildFor.Value>,
            defaultBuildFor: @autoclosure () -> XCSchemeInfo.BuildFor
        ) throws {
            var buildTargetInfo = try getBuildTargetInfo(label, defaultBuildFor: defaultBuildFor())
            try buildTargetInfo.buildFor[keyPath: keyPath].merge(with: .enabled)
            buildTargetInfos[label] = buildTargetInfo
        }

        try scheme.testAction?.targets.forEach { label in
            try enableBuildForValue(label, \.testing, defaultBuildFor: .init())
        }

        // try scheme.buildAction?.targets.map { buildTarget in
        //     let targetInfo = try targetResolver.targetInfo(
        //         targetID: try targetIDsByLabel.value(for: buildTarget.label, context: context)
        //     )
        //     buildTargetInfos[label] = .init(
        //         targetInfo: targetInfo,
        //         buildFor: buildTarget.buildFor
        //     )
        // }

        // TODO(chuck): FINISH ME

        try self.init(targets: buildTargetInfos.values)
    }
}
