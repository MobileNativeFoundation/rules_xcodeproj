import GeneratorCommon
import OrderedCollections
import PBXProj

struct ConsolidatedTarget: Equatable {
    typealias Key = ConsolidationMapEntry.Key

    let key: Key
    let sortedTargets: [Target]

    let label: BazelLabel
    let productType: PBXProductType
}

extension Generator {
    struct ConsolidateTargets {
        private let callable: Callable
        
        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }
        
        /// Attempts to consolidate targets that differ only by configuration.
        ///
        /// - Parameters:
        ///   - targets: All the targets.
        ///   - logger: A `Logger` to output warnings to when certain configuration
        ///     prevents a consolidation.
        func callAsFunction(
            _ targets: [Target],
            logger: Logger
        ) throws -> [ConsolidatedTarget] {
            return try callable(/*targets:*/ targets, /*logger:*/ logger)
        }
    }
}

// MARK: - ConsolidateTargets.Callable

private struct PotentialConsolidatedTargetKey: Equatable, Hashable {
    let ids: Set<TargetID>

    init(_ ids: Set<TargetID>) {
        self.ids = ids
    }
}

extension Generator.ConsolidateTargets {
    public typealias Callable = (
        _ targets: [Target],
        _ logger: Logger
    ) throws -> [ConsolidatedTarget]

    static func defaultCallable(
        _ targets: [Target],
        logger: Logger
    ) throws -> [ConsolidatedTarget] {
        // First pass
        var consolidatable: [ConsolidatableKey: Set<TargetID>] = [:]
        for target in targets {
            consolidatable[.init(target: target), default: []].insert(target.id)
        }

        let targets = Dictionary(
            uniqueKeysWithValues: targets.map { ($0.id, $0) }
        )

        // Filter out multiple targets of the same platform
        // TODO: Eventually we should probably support this, for Universal macOS
        //   binaries. Xcode doesn't respect the `arch` condition for product
        //   directory related build settings, so it's non-trivial to support.
        var consolidateGroups: [Set<TargetID>] = []
        for ids in consolidatable.values {
            // We group by `XcodeConfigurationAndPlatform` to allow matching
            // of the same configured targets, but with different Xcode
            // configuration names or platforms
            var configurations: [
                XcodeConfigurationAndPlatform:
                    [ConsolidationBucketDistinguisher: TargetID]
            ] = [:]
            for id in ids {
                let target = targets[id]!
                let platform = target.platform
                let configuration = ConsolidationBucketDistinguisher(
                    platform: platform,
                    osVersion: target.osVersion,
                    arch: target.arch,
                    id: target.id
                )
                for xcodeConfiguration in target.xcodeConfigurations {
                    let distinguisher = XcodeConfigurationAndPlatform(
                        xcodeConfiguration: xcodeConfiguration,
                        platform: platform
                    )
                    configurations[distinguisher, default: [:]][configuration] =
                        id
                }
            }

            var buckets: [Int: Set<TargetID>] = [:]
            for ids in configurations.values {
                // TODO: Handle situations where a unique configurations messes
                //   up the sorting (e.g. single different minimum os
                //   configuration where the rest of the targets are pairs of
                //   minimum os versions differing by environment)
                let sortedIDs = ids
                    .sorted { $0.key < $1.key }
                    .map(\.value)
                for (idx, id) in sortedIDs.enumerated() {
                    buckets[idx, default: []].insert(id)
                }
            }

            for ids in buckets.values {
                consolidateGroups.append(ids)
            }
        }

        // Build up mappings
        var targetIDMapping: [TargetID: PotentialConsolidatedTargetKey] = [:]
        var keys: Set<PotentialConsolidatedTargetKey> = []
        for ids in consolidateGroups {
            let key = PotentialConsolidatedTargetKey(ids)
            keys.insert(key)
            for id in ids {
                targetIDMapping[id] = key
            }
        }

        // Calculate dependencies
        func resolveDependency(
            _ depID: TargetID,
            for id: TargetID
        ) throws -> PotentialConsolidatedTargetKey {
            guard let dependencyKey = targetIDMapping[depID] else {
                throw PreconditionError(message: """
Target "\(id)" dependency on "\(depID)" not found in `targetIDMapping`
""")
            }
            return dependencyKey
        }

        var depsMap: [TargetID: Set<PotentialConsolidatedTargetKey>] = [:]
        var rdepsMap: [
            PotentialConsolidatedTargetKey: Set<PotentialConsolidatedTargetKey>
        ] = [:]
        func updateDependencies(
            for id: TargetID,
            to key: PotentialConsolidatedTargetKey
        ) throws {
            guard let target = targets[id] else {
                throw PreconditionError(
                    message: #"Target "\#(id)" not found in `targets`"#
                )
            }

            let dependencies: Set<PotentialConsolidatedTargetKey> = try .init(
                target.dependencies.map { depID in
                    return try resolveDependency(depID, for: id)
                }
            )

            depsMap[id] = dependencies
            for dependencyKey in dependencies {
                rdepsMap[dependencyKey, default: []].insert(key)
            }
        }

        func updateDependencies(
            for key: PotentialConsolidatedTargetKey
        ) throws {
            try key.ids.forEach { id in
                try updateDependencies(for: id, to: key)
            }
        }

        try keys.forEach { try updateDependencies(for: $0) }

        var keysToEvaluate = keys.filter { $0.ids.count > 1 }

        // Account for conditional dependencies
        func deconsolidateTarget(
            _ key: PotentialConsolidatedTargetKey,
            into targetIDsForKeys: [Set<TargetID>]
        ) throws {
            keys.remove(key)
            for id in key.ids {
                targetIDMapping.removeValue(forKey: id)
            }

            for targetIDs in targetIDsForKeys {
                let newKey = PotentialConsolidatedTargetKey(targetIDs)
                keys.insert(newKey)
                for id in targetIDs {
                    targetIDMapping[id] = newKey
                }
            }

            // Reevaluate dependent targets
            if let rdeps = rdepsMap.removeValue(forKey: key) {
                for rdep in rdeps {
                    guard keys.contains(rdep) else {
                        // If rdep has already been deconsolidated, we don't
                        // need to do anything with it. And actually doing
                        // anything can lead to errors.
                        continue
                    }
                    try updateDependencies(for: rdep)
                    keysToEvaluate.insert(rdep)
                }
            }
        }

        while !keysToEvaluate.isEmpty {
            let key = keysToEvaluate.popFirst()!
            var depsGrouping:
                [Set<PotentialConsolidatedTargetKey>: Set<TargetID>] = [:]
            for id in key.ids {
                depsGrouping[depsMap[id] ?? [], default: []].insert(id)
            }

            guard depsGrouping.count == 1 else {
                let depGroupingStr = depsGrouping.values
                    .map { "\($0.sorted())" }
                    .sorted()
                    .joined(separator: ", ")
                logger.logWarning("""
Was unable to consolidate target groupings "\(depGroupingStr)" since they have \
conditional dependencies (e.g. `deps`, `test_host`, `watch_application`, etc.)
""")
                try deconsolidateTarget(
                    key,
                    into: Array(depsGrouping.values)
                )
                continue
            }
        }

        return keys.map { key in
            let sortedIds = key.ids.sorted()
            return ConsolidatedTarget(
                key: .init(sortedIds),
                sortedTargets: sortedIds.map { id in targets[id]! }
            )
        }
    }
}

extension ConsolidatedTarget {
    init(key: Key, sortedTargets: [Target]) {
        self.key = key
        self.sortedTargets = sortedTargets

        let aTarget = sortedTargets.first!
        label = aTarget.label
        productType = aTarget.productType
    }
}

/// If multiple targets have the same `ConsolidatableKey`, they can
/// potentially be consolidated. "Potentially", since there are some
/// disqualifying properties that require further inspection (e.g conditional
/// dependencies).
private struct ConsolidatableKey: Equatable, Hashable {
    let label: BazelLabel
    let productType: PBXProductType

    /// Used to prevent watchOS from consolidating with other platforms. Xcode
    /// gets confused when a watchOS App target depends on a consolidated
    /// iOS/watchOS dependency, so we just don't let it get into that situation.
    let isWatchOS: Bool
}

extension ConsolidatableKey {
    init(target: Target) {
        label = target.label
        productType = target.productType
        isWatchOS = target.platform.os == .watchOS
    }
}

private struct XcodeConfigurationAndPlatform: Equatable, Hashable {
    let xcodeConfiguration: String
    let platform: Platform
}

private struct ConsolidationBucketDistinguisher: Equatable, Hashable {
    let platform: Platform
    let osVersion: SemanticVersion
    let arch: String
    let id: TargetID
}

extension ConsolidationBucketDistinguisher: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return (lhs.platform, lhs.osVersion, lhs.arch, lhs.id.rawValue) <
            (rhs.platform, rhs.osVersion, rhs.arch, rhs.id.rawValue)
    }
}
