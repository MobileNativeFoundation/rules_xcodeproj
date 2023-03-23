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
        xcodeConfigurations: Set<String>,
        runnerLabel: BazelLabel
    ) throws -> [String: [BazelLabel: TargetID]] {
        let targets = targetResolver.targets
        let labelTargetInfos = try targetResolver.labelTargetInfos
        let allBazelLabels = allBazelLabels

        var resolvedTargetIDs: [String: [BazelLabel: TargetID]] = [:]
        for configuration in xcodeConfigurations {
            resolvedTargetIDs[configuration] = try resolveTargetIDs(
                configuration: configuration,
                targets: targets,
                labelTargetInfos: labelTargetInfos,
                allBazelLabels: allBazelLabels,
                runnerLabel: runnerLabel
            )
        }

        return resolvedTargetIDs
    }

    private func resolveTargetIDs(
        configuration: String,
        targets: [TargetID: Target],
        labelTargetInfos: [BazelLabel: XcodeScheme.LabelTargetInfo],
        allBazelLabels: Set<BazelLabel>,
        runnerLabel: BazelLabel
    ) throws -> [BazelLabel: TargetID] {
        var resolvedTargetIDs: [BazelLabel: TargetID] = [:]

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

            if let best = try labelTargetInfo
                .bestPerConfiguration[configuration]
            {
                topLevelLabels.insert(label)
                topLevelPlatforms.formUnion(best.platforms)

                let targetID = best.id
                topLevelTargetIDs.insert(targetID)
                resolvedTargetIDs[label] = targetID
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
            // label. Or check for a target that has a matching top-level
            // platform. Or finally pick the default "best" target.
            if let targetID = targets.firstTargetID(
                under: topLevelTargetIDs,
                where: { target in
                    return target.label == label &&
                      target.xcodeConfigurations.contains(configuration)
                }
            ) {
                resolvedTargetIDs[label] = targetID
            } else {
                if let targetWithID = labelTargetInfo.firstCompatibleWith(
                    anyOf: topLevelPlatforms,
                    configuration: configuration
                ) {
                    resolvedTargetIDs[label] = targetWithID.id
                } else if let best =
                    try labelTargetInfo.bestPerConfiguration[configuration]
                {
                    resolvedTargetIDs[label] = best.id
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
        struct ConfigurationInfo {
            var targetsInPlatformOrder: [TargetWithID] = []
            var platforms: Set<Platform> = []
        }

        let label: BazelLabel
        let isTopLevel: Bool
        var configurationInfos: [String: ConfigurationInfo] = [:]
    }
}

extension XcodeScheme.LabelTargetInfo {
    mutating func add(_ targetWithID: XcodeScheme.TargetWithID) {
        for configuration in targetWithID.target.xcodeConfigurations {
            var configurationInfo =
                configurationInfos[configuration, default: .init()]
            configurationInfo.targetsInPlatformOrder.append(targetWithID)
            configurationInfo.targetsInPlatformOrder.sort()
            configurationInfo.platforms
                .update(with: targetWithID.target.platform)
            configurationInfos[configuration] = configurationInfo
        }
    }
}

extension XcodeScheme.LabelTargetInfo {
    struct ConfigurationWithBest: Equatable {
        let id: TargetID
        let platforms: Set<Platform>
    }

    var bestPerConfiguration: [String: ConfigurationWithBest] {
        get throws {
            guard !configurationInfos.isEmpty else {
                throw PreconditionError(message: """
Unable to find the best `TargetWithID` for "\(label)"
""")
            }
            return try configurationInfos.mapValues { configurationInfo in
                return try ConfigurationWithBest(
                    id: configurationInfo.targetsInPlatformOrder
                        .first.orThrow("""
Unable to find the best `TargetWithID` for "\(label)"
""")
                        .id,
                    platforms: configurationInfo.platforms
                )
            }
        }
    }
}

extension XcodeScheme.LabelTargetInfo {
    func firstCompatibleWith<Platforms: Sequence>(
        anyOf platforms: Platforms,
        configuration: String
    ) -> XcodeScheme.TargetWithID?
    where Platforms.Element == Platform {
        guard let configurationInfo = configurationInfos[configuration] else {
            return nil
        }
        return configurationInfo.targetsInPlatformOrder.first(
            where: { targetWithID in
                targetWithID.target.platform.compatibleWith(
                    anyOf: platforms
                )
            }
        )
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
