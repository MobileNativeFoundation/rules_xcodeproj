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

extension XcodeScheme.TargetWithID: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: BazelLabel

extension XcodeScheme {
    struct SchemeLabel {
        let label: String
        let isTopLevel: Bool
    }
}

// MARK: Resolve TargetIDs

extension XcodeScheme {
    // typealias ByBuildSettingC
    // // The Bazel label as a string
    // typealias ByLabelValue = String

    // private func groupTargetWithIDsByLabel(targetWithIDs: [TargetWithID]) -> [String: [Targetg]]

    func resolveTargetIDs(targets _: [TargetID: Target]) -> [String: Set<TargetID>] {
        // TODO: Consider how to reduce recreating topLevelTargetLabels multiple times. Perhaps,
        // create TargetID resolver.

        // let targetWithIDs = targets.map { id, target in
        //     TargetWithID(id: id, target: target)
        // }
        // // let targetWithIDsByLabel = Dictionary(grouping: targetWithIDs, by: { $0.target.label })

        // let allTargets = allTargets
        // let topLevelTargets = allTargets.filter(\.isTopLevel)
        // let configurations = Set<String>(
        //     topLevelTargets.isEmpty ? [] : topLevelTargetLabels.map(\.configuration)
        // )

        // // If no configurations, then pick the "best" configuration
        // if configurations.isEmpty {
        //     // TODO: Pick the best config
        // } else {
        //     // TODO: Select targets based upon the top-level configurations

        //     // For each label in the scheme,
        // }

        // Get all of the scheme labels
        // Collect top-level configurations
        // For each schemeLabel,
            // If schemeLabel is top-level, then get the Target-TargetID with the "best" platform
            // If schemeLabel is not top-level, then collect all of the Target-TargetID for the
            // top-level configurations

        // let resolvedTargetIDs: [String: Set<TargetID>]
        // return resolvedTargetIDs

        // TODO: IMPLEMENT ME!
        return [:]
    }
}

extension XcodeScheme {
    private var topLevelTargetLabels: Set<String> {
        var results = Set<String>()
        if let testAction = testAction {
            testAction.targets.forEach { results.update(with: $0) }
        }
        if let launchAction = launchAction {
            results.update(with: launchAction.target)
        }
        return results
    }

    var allLabels: [SchemeLabel] {
        let topLevelTargetLabels = topLevelTargetLabels

        var results = [SchemeLabel]()
        for label in topLevelTargetLabels {
            results.append(.init(label: label, isTopLevel: true))
        }
        if let buildAction = buildAction {
            for label in buildAction.targets {
                results.append(.init(
                    label: label,
                    isTopLevel: topLevelTargetLabels.contains(label)
                ))
            }
        }

        return results
    }
}

// // MARK: Top-Level Targets

// extension XcodeScheme {
//     var topLevelTargetLabels: Set<SchemeLabel> {
//         var results = Set<String>()
//         if let testAction = testAction {
//             testAction.targets.forEach { results.update($0) }
//         }
//         if let launchAction = launchAction {
//             results.update(launchAction.target)
//         }
//         return results
//     }
// }
