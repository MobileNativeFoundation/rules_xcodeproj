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
    init?(
        buildAction: XcodeScheme.BuildAction?,
        targetResolver: TargetResolver,
        targetIDsByLabel: [BazelLabel: TargetID]
    ) throws {
        guard let buildAction = buildAction else {
            return nil
        }
        let buildTargetInfos: [XCSchemeInfo.BuildTargetInfo] = try buildAction.targets
            .map { buildTarget in
                let targetID = try targetIDsByLabel.value(
                    for: buildTarget.label,
                    context: "creating a `BuildActionInfo`"
                )
                return XCSchemeInfo.BuildTargetInfo(
                    targetInfo: try targetResolver.targetInfo(targetID: targetID),
                    buildFor: buildTarget.buildFor
                )
            }
        try self.init(targets: buildTargetInfos)
    }
}

// extension XCSchemeInfo.BuildActionInfo {
//     init(
//         scheme: XcodeScheme,
//         targetResolver: TargetResolver,
//         targetIDsByLabel: [BazelLabel: TargetID]
//     ) throws {
//         let context = "creating a `BuildActionInfo`"
//         var buildTargetInfos = [BazelLabel: XCSchemeInfo.BuildTargetInfo]()

//         func createTargetInfo(_ label: BazelLabel) throws -> XCSchemeInfo.TargetInfo {
//             return try targetResolver.targetInfo(
//                 targetID: try targetIDsByLabel.value(for: label, context: context)
//             )
//         }

//         func getBuildTargetInfo(
//             _ label: BazelLabel,
//             defaultBuildFor: @autoclosure () -> XcodeScheme.BuildFor
//         ) throws -> XCSchemeInfo.BuildTargetInfo {
//             if let existing = buildTargetInfos[label] {
//                 return existing
//             }
//             let new = XCSchemeInfo.BuildTargetInfo(
//                 targetInfo: try createTargetInfo(label),
//                 buildFor: defaultBuildFor()
//             )
//             buildTargetInfos[label] = new
//             return new
//         }

//         func enableBuildForValue(
//             _ label: BazelLabel,
//             _ keyPath: WritableKeyPath<XcodeScheme.BuildFor, XcodeScheme.BuildFor.Value>
//         ) throws {
//             var buildTargetInfo = try getBuildTargetInfo(label, defaultBuildFor: .init())
//             try buildTargetInfo.buildFor[keyPath: keyPath].merge(with: .enabled)
//             buildTargetInfos[label] = buildTargetInfo
//         }

//         try scheme.buildAction?.targets.forEach { buildTarget in
//             // We are guaranteed not to have build targets with duplicate labels. So, we can just
//             // create build target infos for these.
//             buildTargetInfos[buildTarget.label] = XCSchemeInfo.BuildTargetInfo(
//                 targetInfo: try createTargetInfo(buildTarget.label),
//                 buildFor: buildTarget.buildFor
//             )
//         }
//         try scheme.testAction?.targets.forEach { try enableBuildForValue($0, \.testing) }
//         try scheme.launchAction.map { try enableBuildForValue($0.target, \.running) }
//         try scheme.profileAction.map { try enableBuildForValue($0.target, \.profiling) }

//         try self.init(targets: buildTargetInfos.values)
//     }
// }
