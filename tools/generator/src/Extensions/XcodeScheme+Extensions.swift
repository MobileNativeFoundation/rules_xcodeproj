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

// MARK: LabelAndConfiguration

extension XcodeScheme {
    struct LabelAndConfiguration: Equatable, Hashable {
        let label: BazelLabel
        let configuration: String

        init(_ label: BazelLabel, _ configuration: String) {
            self.label = label
            self.configuration = configuration
        }
    }
}

// MARK: Resolve TargetIDs

extension XcodeScheme {
    func aliasErrorMessage(runnerLabel: BazelLabel, missingLabel: BazelLabel) -> String {
        return """
Target \(missingLabel) was not found in the transitive dependencies of \(runnerLabel)'s \
`top_level_targets` attribute. Did you reference an alias (only actual target labels are \
supported in Scheme definitions)? Check that \(missingLabel) is spelled correctly, and if it is, \
add it or a target that depends on it to \(runnerLabel)'s `top_level_targets` attribute.
"""
    }

    /// Determines the mapping of `BazelLabel` to the `TargetID` values based
    /// upon the scheme's configuration.
    func resolveTargetIDs(
        targetResolver: TargetResolver,
        runnerLabel: BazelLabel
    ) throws -> [LabelAndConfiguration: TargetID] {
        var resolvedTargetIDs = [LabelAndConfiguration: TargetID]()

        let targets = targetResolver.targets

        let labelTargetInfos = try targetResolver.labelTargetInfos
        let allBazelLabels = allBazelLabels

        // Identify the top-level targets
        var topLevelLabels: Set<BazelLabel> = []
        var topLevelTargetIDs: Set<TargetID> = []
        var topLevelPlatforms: Set<Platform> = []
        for label in allBazelLabels {
            let labelTargetInfo = try labelTargetInfos.value(
                for: label,
                message: aliasErrorMessage(
                    runnerLabel: runnerLabel,
                    missingLabel: label
                )
            )
            guard labelTargetInfo.isTopLevel else {
                continue
            }

            topLevelLabels.insert(label)
            topLevelPlatforms.formUnion(labelTargetInfo.platforms)

            for (configuration, best) in try labelTargetInfo
                .bestPerConfiguration
            {
                let targetID = best.id
                topLevelTargetIDs.insert(targetID)
                resolvedTargetIDs[.init(label, configuration)] = targetID
            }
        }

        let otherLabels = allBazelLabels.subtracting(topLevelLabels)
        for label in otherLabels {
            let labelTargetInfo = try labelTargetInfos.value(
                for: label,
                message: aliasErrorMessage(
                    runnerLabel: runnerLabel,
                    missingLabel: label
                )
            )

            // Check for dependency of a top-level target that matches the
            // label. Check for target that has a matching top-level platform.
            // Pick the default "best" target.
            if let targetID = targets.firstTargetID(
                under: topLevelTargetIDs,
                where: { $0.label == label }
            ) {
                let target = targets[targetID]!
                for configuration in target.xcodeConfigurations {
                    resolvedTargetIDs[.init(label, configuration)] = targetID
                }
            } else {
                let targetWithIDs = labelTargetInfo.firstCompatibleWith(
                    anyOf: topLevelPlatforms
                )
                if !targetWithIDs.isEmpty {
                    for (configuration, targetWithID) in targetWithIDs {
                        resolvedTargetIDs[.init(label, configuration)] =
                        targetWithID.id
                    }
                } else {
                    for (configuration, best) in try labelTargetInfo
                        .bestPerConfiguration
                    {
                        resolvedTargetIDs[.init(label, configuration)] = best.id
                    }
                }
            }
        }

        return resolvedTargetIDs
    }
}

extension TargetResolver {
    var labelTargetInfos: [BazelLabel: XcodeScheme.LabelTargetInfo] {
        get throws {
            var results = [BazelLabel: XcodeScheme.LabelTargetInfo]()

            // Collect the target information
            for (targetID, target) in targets {
                let targetWithID = XcodeScheme
                    .TargetWithID(id: targetID, target: target)
                let isTopLevel = try pbxTargetInfo(for: targetID)
                    .pbxTarget.isTopLevel
                results[target.label, default: .init(
                    label: target.label,
                    isTopLevel: isTopLevel
                )].add(targetWithID)
            }

            return results
        }
    }
}

// MARK: LabelTargetInfo

extension XcodeScheme {
    /// Collects Target information for a BazelLabel.
    struct LabelTargetInfo {
        let label: BazelLabel
        let isTopLevel: Bool
        var inPlatformOrder: [String: [TargetWithID]] = [:]
        var platforms = Set<Platform>()
    }
}

extension XcodeScheme.LabelTargetInfo {
    mutating func add(_ targetWithID: XcodeScheme.TargetWithID) {
        for configuration in targetWithID.target.xcodeConfigurations {
            var configurationInPlatformOrder =
                inPlatformOrder[configuration, default: []]
            configurationInPlatformOrder.append(targetWithID)
            configurationInPlatformOrder.sort()
            inPlatformOrder[configuration] = configurationInPlatformOrder
        }
        platforms.update(with: targetWithID.target.platform)
    }
}

extension XcodeScheme.LabelTargetInfo {
    var bestPerConfiguration: [String: XcodeScheme.TargetWithID] {
        get throws {
            guard !inPlatformOrder.isEmpty else {
                throw PreconditionError(message: """
Unable to find the best `TargetWithID` for "\(label)"
""")
            }
            return try inPlatformOrder.mapValues { configurationInPlatformOrder in
                try configurationInPlatformOrder.first.orThrow("""
Unable to find the best `TargetWithID` for "\(label)"
""")
            }
        }
    }
}

extension XcodeScheme.LabelTargetInfo {
    func firstCompatibleWith<Platforms: Sequence>(
        anyOf platforms: Platforms
    ) -> [String: XcodeScheme.TargetWithID]
    where Platforms.Element == Platform {
        var result: [String: XcodeScheme.TargetWithID] = [:]
        for (configuration, configurationInPlatformOrder) in inPlatformOrder {
            guard let targetWithID = configurationInPlatformOrder
                .first(where: { targetWithID in
                    targetWithID.target.platform.compatibleWith(
                        anyOf: platforms
                    )
                })
            else {
                continue
            }
            result[configuration] = targetWithID
        }
        return result
    }
}

// MARK: Collect the BazelLabel Values

extension XcodeScheme {
    /// Retrieve all of the labels specified in the scheme.
    var allBazelLabels: Set<BazelLabel> {
        var labels = Set<BazelLabel>()
        if let buildAction = buildAction {
            labels.formUnion(buildAction.targets.map(\.label))
            labels.formUnion(buildAction.preActions.compactMap(
                \.expandVariablesBasedOn
            ))
            labels.formUnion(buildAction.postActions.compactMap(
                \.expandVariablesBasedOn
            ))
        }
        if let testAction = testAction {
            labels.formUnion(testAction.targets)
            labels.formUnion(testAction.preActions.compactMap(
                \.expandVariablesBasedOn
            ))
            labels.formUnion(testAction.postActions.compactMap(
                \.expandVariablesBasedOn
            ))
        }
        if let launchAction = launchAction {
            labels.update(with: launchAction.target)
        }
        if let profileAction = profileAction {
            labels.update(with: profileAction.target)
        }
        return labels
    }
}
