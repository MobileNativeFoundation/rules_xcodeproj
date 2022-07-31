// MARK: TargetWithID

extension XcodeScheme {
    struct TargetWithID {
        let id: TargetID
        let target: Target
    }
}

extension XcodeScheme.TargetWithID: Equatable {
    static func == (lhs: XcodeScheme.TargetWithID, rhs: XcodeScheme.TargetWithID) -> Bool {
        return lhs.id == rhs.id
    }
}

extension XcodeScheme.TargetWithID: Comparable {
    static func < (lhs: XcodeScheme.TargetWithID, rhs: XcodeScheme.TargetWithID) -> Bool {
        return lhs.target.platform < rhs.target.platform
    }
}

// MARK: Resolve TargetIDs

extension XcodeScheme {
    /// Represents a configuration string (Target.configuration).
    typealias Configuration = String

    static let aliasErrorMessage = """

Are you using an `alias`? Custom scheme definitions require labels of actual targets.
"""

    /// Determines the mapping of `BazelLabel` to the `TargetID` values based upon the scheme's
    /// configuration.
    func resolveTargetIDs(targets: [TargetID: Target]) throws -> [BazelLabel: TargetID] {
        var resolvedTargetIDs = [BazelLabel: TargetID]()

        let labelTargetInfos = targets.asTargetWithIDs.collectedByLabelTargetInfo
        let allBazelLabels = allBazelLabels

        // Identify the top-level targets
        var topLevelLabels = Set<BazelLabel>()
        var topLevelTargetIDs = Set<TargetID>()
        var topLevelPlatforms = Set<Platform>()
        for label in allBazelLabels {
            let labelTargetInfo = try labelTargetInfos.value(
                for: label,
                context: "resolving top-level targets in scheme, \(name)"
                // TODO(chuck): Add aliasErrorMessage
            )
            guard labelTargetInfo.isTopLevel else {
                continue
            }
            topLevelLabels.update(with: label)
            topLevelPlatforms.formUnion(labelTargetInfo.platforms)
            let targetID = try labelTargetInfo.best().id
            topLevelTargetIDs.update(with: targetID)
            resolvedTargetIDs[label] = targetID
        }

        let otherLabels = allBazelLabels.subtracting(topLevelLabels)
        for label in otherLabels {
            let labelTargetInfo = try labelTargetInfos.value(
                for: label,
                context: "resolving other targets in scheme, \(name)"
                // TODO(chuck): Add aliasErrorMessage
            )

            // Check for depedency of a top-level target that matches the label.
            // Check for target that has a matching top-level platform
            // Pick the default "best" target
            let resolvedTargetID: TargetID
            if let targetID = try targets.firstTargetID(
                under: topLevelTargetIDs,
                where: { $0.label == label }
            ) {
                resolvedTargetID = targetID
            } else if let targetWithID = labelTargetInfo.firstCompatibleWith(
                anyOf: topLevelPlatforms
            ) {
                resolvedTargetID = targetWithID.id
            } else {
                resolvedTargetID = try labelTargetInfo.best().id
            }
            resolvedTargetIDs[label] = resolvedTargetID
        }

        return resolvedTargetIDs
    }

    // func resolveTargetIDs(targets: [TargetID: Target]) throws -> [BazelLabel: TargetID] {
    //     // Get all of the scheme labels
    //     let allSchemeLabels = allSchemeLabels
    //     let topLevelSchemeLabels = allSchemeLabels.filter(\.isTopLevel)
    //     let otherSchemeLabels = allSchemeLabels.subtracting(topLevelSchemeLabels)

    //     // Gather target info for the top-level targets
    //     let topLevelLabels = Set(topLevelSchemeLabels.map(\.label))
    //     let topLevelTargetWithIDs = targets
    //         .filter { _, target in topLevelLabels.contains(target.label) }
    //         .map { id, target in TargetWithID(id: id, target: target) }
    //     let topLevelTargetInfoByLabelValue = collectTargetInfoByLabelValue(
    //         targetWithIDs: topLevelTargetWithIDs
    //     )

    //     var resolvedTargetIDs = [BazelLabel: TargetID]()

    //     // Collect top-level targetIDs
    //     var topLevelTargetIDs = Set<TargetID>()
    //     var topLevelPlatforms = Set<Platform>()
    //     for schemeLabel in topLevelSchemeLabels {
    //         guard let targetInfo = topLevelTargetInfoByLabelValue[schemeLabel.label] else {
    //             throw PreconditionError(message: """
// Did not find `targetInfo` for top-level label "\(schemeLabel.label)"
// \(Self.aliasErrorMessage)
// """)
    //         }
    //         let targetID = try targetInfo.best().id
    //         topLevelTargetIDs.update(with: targetID)
    //         topLevelPlatforms.formUnion(targetInfo.platforms)
    //         resolvedTargetIDs[schemeLabel.label] = targetID
    //     }

    //     // Reduce the number of targets being evaluated. Only include those that have one of the
    //     // top-level platforms.
    //     let targetsWithTopLevelPlatforms = targets.filterDependencyTree(
    //         startingWith: topLevelTargetIDs
    //     ) { target in
    //         topLevelPlatforms.contains(target.platform)
    //     }

    //     // Collect other targetIDs
    //     for schemeLabel in otherSchemeLabels {
    //         // If schemeLabel is not top-level, then look for the first occurence of the label
    //         // as a dependency of the top-level targets.
    //         let firstDepTargetID = targetsWithTopLevelPlatforms
    //             .firstTargetID(under: topLevelTargetIDs) { $0.label == schemeLabel.label }
    //         guard let targetID = firstDepTargetID else {
    //             throw PreconditionError(message: """
// No `TargetID` value found for "\(schemeLabel.label)"
// \(Self.aliasErrorMessage)
// """)
    //         }
    //         resolvedTargetIDs[schemeLabel.label] = targetID
    //     }

    //     return resolvedTargetIDs
    // }
}

extension Dictionary where Key == TargetID, Value == Target {
    var asTargetWithIDs: [XcodeScheme.TargetWithID] {
        return map { id, target in .init(id: id, target: target) }
    }
}

extension Sequence where Element == XcodeScheme.TargetWithID {
    var collectedByLabelTargetInfo: [BazelLabel: XcodeScheme.LabelTargetInfo] {
        var results = [BazelLabel: XcodeScheme.LabelTargetInfo]()

        // Collect the target information
        for targetWithID in self {
            let target = targetWithID.target
            var targetInfo = results[target.label, default: .init(label: target.label)]
            targetInfo.platforms.update(with: target.platform)
            targetInfo.inPlatformOrder.append(targetWithID)
            targetInfo.inPlatformOrder.sort()
            results[target.label] = targetInfo
        }

        return results
    }
}

// MARK: LabelTargetInfo

extension XcodeScheme {
    /// Collects Target information for a BazelLabel.
    struct LabelTargetInfo {
        let label: BazelLabel
        var inPlatformOrder = [TargetWithID]()
        var platforms = Set<Platform>()

        func best() throws -> TargetWithID {
            guard let best = inPlatformOrder.first else {
                throw PreconditionError(message: """
Unable to find the best `TargetWithID` for "\(label)"
""")
            }
            return best
        }

        func firstCompatibleWith<Platforms: Sequence>(
            anyOf platforms: Platforms
        ) -> TargetWithID? where Platforms.Element == Platform {
            let uniquePlatforms = Set(platforms)
            for targetWithID in inPlatformOrder {
                if uniquePlatforms.contains(targetWithID.target.platform) {
                    return targetWithID
                }
            }
            return nil
        }

        var isTopLevel: Bool {
            // TODO(chuck): IMPLEMENT ME!
            return false
        }
    }

    // private func collectTargetInfoByLabelValue(
    //     targetWithIDs: [TargetWithID]
    // ) -> [BazelLabel: LabelTargetInfo] {
    //     var results = [BazelLabel: LabelTargetInfo]()

    //     // Collect the target information
    //     for targetWithID in targetWithIDs {
    //         let target = targetWithID.target
    //         var targetInfo = results[
    //             target.label, default: LabelTargetInfo(label: target.label)
    //         ]
    //         targetInfo.platforms.update(with: target.platform)
    //         targetInfo.inPlatformOrder.append(targetWithID)
    //         targetInfo.inPlatformOrder.sort()
    //         results[target.label] = targetInfo
    //     }

    //     return results
    // }
}

// MARK: Collect the SchemeLabel Values

extension XcodeScheme {
    // /// Represents a Bazel label from a scheme.
    // struct SchemeLabel: Equatable, Hashable {
    //     let label: BazelLabel
    //     let isTopLevel: Bool
    // }

    // private var topLevelTargetLabels: Set<BazelLabel> {
    //     var results = Set<BazelLabel>()
    //     if let testAction = testAction {
    //         testAction.targets.forEach { results.update(with: $0) }
    //     }
    //     if let launchAction = launchAction {
    //         results.update(with: launchAction.target)
    //     }
    //     return results
    // }

    /// Retrieve all of the labels specified in the scheme.
    var allBazelLabels: Set<BazelLabel> {
        var labels = Set<BazelLabel>()
        if let buildAction = buildAction {
            labels.formUnion(buildAction.targets)
        }
        if let testAction = testAction {
            labels.formUnion(testAction.targets)
        }
        if let launchAction = launchAction {
            labels.update(with: launchAction.target)
        }
        return labels
    }
    // var allSchemeLabels: Set<SchemeLabel> {
    //     let topLevelTargetLabels = topLevelTargetLabels

    //     var byLabelValue = [BazelLabel: SchemeLabel]()
    //     for label in topLevelTargetLabels {
    //         byLabelValue[label] = .init(label: label, isTopLevel: true)
    //     }
    //     if let buildAction = buildAction {
    //         for label in buildAction.targets {
    //             if byLabelValue[label] != nil {
    //                 continue
    //             }
    //             byLabelValue[label] = .init(
    //                 label: label,
    //                 isTopLevel: topLevelTargetLabels.contains(label)
    //             )
    //         }
    //     }

    //     return .init(byLabelValue.values)
    // }
}

// MARK: Create a BuildAction with All Targets

extension XcodeScheme.BuildAction {
    init<Targets: Sequence>(
        original: XcodeScheme.BuildAction?,
        otherTargets: Targets
    ) where Targets.Element == BazelLabel {
        var allTargets = Set<BazelLabel>()
        allTargets.formUnion(otherTargets)
        if let original = original {
            // Once we add other attributes to BuildAction, these should be copied to the new
            // instance.

            // Gather any targets from the client's description.
            allTargets.formUnion(original.targets)
        }
        self.init(targets: allTargets)
    }
}

extension XcodeScheme {
    var buildActionWithAllTargets: XcodeScheme.BuildAction {
        return .init(original: buildAction, otherTargets: allBazelLabels)
    }
}
