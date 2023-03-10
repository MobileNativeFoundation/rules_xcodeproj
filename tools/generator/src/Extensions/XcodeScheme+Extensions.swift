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

    /// Determines the mapping of `BazelLabel` to the `TargetID` values based upon the scheme's
    /// configuration.
    func resolveTargetIDs(
        targetResolver: TargetResolver,
        runnerLabel: BazelLabel
    ) throws -> [BazelLabel: TargetID] {
        var resolvedTargetIDs = [BazelLabel: TargetID]()

        let targets = targetResolver.targets

        let labelTargetInfos = try targetResolver.labelTargetInfos
        let allBazelLabels = allBazelLabels

        // Identify the top-level targets
        var topLevelLabels = Set<BazelLabel>()
        var topLevelTargetIDs = Set<TargetID>()
        var topLevelPlatforms = Set<Platform>()
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
            topLevelLabels.update(with: label)
            topLevelPlatforms.formUnion(labelTargetInfo.platforms)
            let targetID = try labelTargetInfo.best.id
            topLevelTargetIDs.update(with: targetID)
            resolvedTargetIDs[label] = targetID
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

            // Check for depedency of a top-level target that matches the label.
            // Check for target that has a matching top-level platform
            // Pick the default "best" target
            let resolvedTargetID: TargetID
            if let targetID = targets.firstTargetID(
                under: topLevelTargetIDs,
                where: { $0.label == label }
            ) {
                resolvedTargetID = targetID
            } else if let targetWithID = labelTargetInfo.firstCompatibleWith(
                anyOf: topLevelPlatforms
            ) {
                resolvedTargetID = targetWithID.id
            } else {
                resolvedTargetID = try labelTargetInfo.best.id
            }
            resolvedTargetIDs[label] = resolvedTargetID
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
                let targetWithID = XcodeScheme.TargetWithID(id: targetID, target: target)
                var targetInfo = try results[target.label] ?? .init(
                    label: target.label,
                    isTopLevel: try pbxTargetInfo(for: targetID).pbxTarget.isTopLevel
                )
                targetInfo.add(targetWithID)
                results[target.label] = targetInfo
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
        var inPlatformOrder = [TargetWithID]()
        var platforms = Set<Platform>()
    }
}

extension XcodeScheme.LabelTargetInfo {
    mutating func add(_ targetWithID: XcodeScheme.TargetWithID) {
        inPlatformOrder.append(targetWithID)
        inPlatformOrder.sort()
        platforms.update(with: targetWithID.target.platform)
    }
}

extension XcodeScheme.LabelTargetInfo {
    var best: XcodeScheme.TargetWithID {
        get throws {
            return try inPlatformOrder.first.orThrow("""
Unable to find the best `TargetWithID` for "\(label)"
""")
        }
    }
}

extension XcodeScheme.LabelTargetInfo {
    func firstCompatibleWith<Platforms: Sequence>(
        anyOf platforms: Platforms
    ) -> XcodeScheme.TargetWithID? where Platforms.Element == Platform {
        return inPlatformOrder.first { $0.target.platform.compatibleWith(anyOf: platforms) }
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
