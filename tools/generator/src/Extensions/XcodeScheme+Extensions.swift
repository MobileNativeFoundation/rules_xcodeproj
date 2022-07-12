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

// extension XcodeScheme.TargetWithID: Hashable {
//     func hash(into hasher: inout Hasher) {
//         hasher.combine(id)
//     }
// }

// MARK: BazelLabel

// extension XcodeScheme {
//     struct SchemeLabel {
//         let label: LabelValue
//         let isTopLevel: Bool
//     }
// }

// MARK: Resolve TargetIDs

extension XcodeScheme {
    // The Bazel label as a string (Target.label)
    typealias LabelValue = String

    // The configuration string (Target.configuration)
    typealias Configuration = String

    // Represents a Bazel label from a scheme
    typealias SchemeLabel = (label: LabelValue, isTopLevel: Bool)

    typealias LabelValueTargetInfo = (
        byConfiguration: [Configuration: TargetWithID],
        // inPlatformOrder: [TargetWithID]
        best: TargetWithID
    )

    private func collectTargetInfoByLabelValue(
        targetWithIDs _: [TargetWithID]
    ) -> [LabelValue: LabelValueTargetInfo] {
        // TODO: IMPLEMENT ME!
        return [:]
    }

    func resolveTargetIDs(targets: [TargetID: Target]) throws -> [LabelValue: [TargetID]] {
        // Get all of the scheme labels
        let allSchemeLabels = allSchemeLabels

        // Create a list of TargetWithID values for the labels that we care about
        let allLabelValues = Set(allSchemeLabels.map(\.label))
        let targetWithIDs = targets
            // We only need target info for labels explicitly mentioned in the scheme
            .filter { _, target in
                allLabelValues.contains(target.label)
            }
            .map { id, target in
                TargetWithID(id: id, target: target)
            }
        let targetInfoByLabelValue = collectTargetInfoByLabelValue(targetWithIDs: targetWithIDs)

        // Collect top-level configurations
        let topLevelLabelValues = allSchemeLabels.filter(\.isTopLevel).map(\.label)
        let topLevelConfigurations = Set(
            targetWithIDs
                .filter { topLevelLabelValues.contains($0.target.label) }
                .map(\.target.configuration)
        )

        // For each schemeLabel,
        var resolvedTargetIDs = [LabelValue: [TargetID]]()
        for schemeLabel in allSchemeLabels {
            guard let targetInfo = targetInfoByLabelValue[schemeLabel.label] else {
                throw PreconditionError(message: """
Did not find `targetInfo` for label "\(schemeLabel.label)"
""")
            }

            let targetIDs: [TargetID]
            if schemeLabel.isTopLevel {
                // If schemeLabel is top-level, then get the Target-TargetID with the "best" platform
                targetIDs = [targetInfo.best.id]
            } else {
                // If schemeLabel is not top-level, then collect all of the Target-TargetID for the
                // top-level configurations
                targetIDs = topLevelConfigurations
                    .compactMap { targetInfo.byConfiguration[$0]?.id }
                    // .flatMap { $0 }
            }
            resolvedTargetIDs[schemeLabel.label] = targetIDs
        }

        return resolvedTargetIDs
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

    var allSchemeLabels: [SchemeLabel] {
        let topLevelTargetLabels = topLevelTargetLabels

        var results = [SchemeLabel]()
        for label in topLevelTargetLabels {
            results.append((label: label, isTopLevel: true))
        }
        if let buildAction = buildAction {
            for label in buildAction.targets {
                results.append((
                    label: label,
                    isTopLevel: topLevelTargetLabels.contains(label)
                ))
            }
        }

        return results
    }
}
