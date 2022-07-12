import OrderedCollections

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

    /// Determines the mapping of `LabelValue` to the `TargetID` values based upon the scheme's
    /// configuration.
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
                targetIDs = [try targetInfo.best().id]
            } else {
                // If schemeLabel is not top-level, then collect all of the Target-TargetID for the
                // top-level configurations
                targetIDs = topLevelConfigurations
                    .compactMap { targetInfo.byConfiguration[$0]?.id }
            }
            resolvedTargetIDs[schemeLabel.label] = targetIDs
        }

        return resolvedTargetIDs
    }
}

// MARK: LabelValueTargetInfo

extension XcodeScheme {
    /// Collects Target information for a LabelValue.
    struct LabelValueTargetInfo {
        let label: LabelValue
        var byConfiguration: [Configuration: TargetWithID] = [:]
        var inPlatformOrder: [TargetWithID] = []

        func best() throws -> TargetWithID {
            guard let best = inPlatformOrder.first else {
                throw PreconditionError(message: """
Unable to find the best `TargetWithID` for "\(label)"
""")
            }
            return best
        }
    }

    private func collectTargetInfoByLabelValue(
        targetWithIDs: [TargetWithID]
    ) -> [LabelValue: LabelValueTargetInfo] {
        var results = [LabelValue: LabelValueTargetInfo]()

        // Collect the target information
        for targetWithID in targetWithIDs {
            let target = targetWithID.target
            var targetInfo = results[
                target.label, default: LabelValueTargetInfo(label: target.label)
            ]
            targetInfo.byConfiguration[target.configuration] = targetWithID
            targetInfo.inPlatformOrder.append(targetWithID)
            targetInfo.inPlatformOrder.sort()
            results[target.label] = targetInfo
        }

        return results
    }
}

// MARK: Collect the SchemeLabel Values

extension XcodeScheme {
    /// Represents a Bazel label from a scheme.
    // typealias SchemeLabel = (label: LabelValue, isTopLevel: Bool)
    struct SchemeLabel: Equatable, Hashable {
        let label: LabelValue
        let isTopLevel: Bool
    }

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

    var allSchemeLabels: Set<SchemeLabel> {
        let topLevelTargetLabels = topLevelTargetLabels

        var byLabelValue = [LabelValue: SchemeLabel]()
        for label in topLevelTargetLabels {
            byLabelValue[label] = .init(label: label, isTopLevel: true)
        }
        if let buildAction = buildAction {
            for label in buildAction.targets {
                if byLabelValue[label] != nil {
                    continue
                }
                byLabelValue[label] = .init(
                    label: label,
                    isTopLevel: topLevelTargetLabels.contains(label)
                )
            }
        }

        return .init(byLabelValue.values)
    }
}
