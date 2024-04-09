import Foundation
import OrderedCollections
import PBXProj

extension Generator {
    struct CalculateConsolidationMaps {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the contents of the consolidation maps.
        func callAsFunction(
            identifiedTargets: [IdentifiedTarget],
            identifiedTargetsMap: OrderedDictionary<TargetID, IdentifiedTarget>
        ) throws -> [URL: [ConsolidationMapEntry]] {
            return try callable(
                /*identifiedTargets:*/ identifiedTargets,
                /*identifiedTargetsMap:*/ identifiedTargetsMap
            )
        }
    }
}

// MARK: - CalculateConsolidationMaps.Callable

extension Generator.CalculateConsolidationMaps {
    typealias Callable = (
        _ identifiedTargets: [IdentifiedTarget],
        _ identifiedTargetsMap: OrderedDictionary<TargetID, IdentifiedTarget>
    ) throws -> [URL: [ConsolidationMapEntry]]

    static func defaultCallable(
        identifiedTargets: [IdentifiedTarget],
        identifiedTargetsMap: OrderedDictionary<TargetID, IdentifiedTarget>
    ) throws -> [URL: [ConsolidationMapEntry]] {
        var consolidationMaps: [URL: [ConsolidationMapEntry]] = [:]
        for target in identifiedTargets {
            let identifier = target.identifier

            let watchKitExtensionProductIdentifier =
                try target.watchKitExtension.flatMap { id in
                    let watchKitExtension = try identifiedTargetsMap
                        .value(for: id ,context: "WatchKit extension")

                    return Identifiers.BuildFiles.productIdentifier(
                        targetSubIdentifier:
                            watchKitExtension.identifier.subIdentifier,
                        productBasename: watchKitExtension.productBasename
                    )
                }

            var depSubIdentifiers: [Identifiers.Targets.SubIdentifier] = [
                .bazelDependencies,
            ]
            depSubIdentifiers
                .append(contentsOf: target.dependencies.compactMap { id in
                    guard let dependency = identifiedTargetsMap[id] else {
                        // We don't throw here because the dependency was
                        // probably a "potential test host" that became
                        // unfocused
                        return nil
                    }
                    return dependency.identifier.subIdentifier
                })

            consolidationMaps[target.consolidationMapOutputPath, default: []]
                .append(
                    ConsolidationMapEntry(
                        key: target.key,
                        label: target.label,
                        productType: target.productType,
                        name: target.name,
                        originalProductBasename: target.originalProductBasename,
                        uiTestHostName: target.uiTestHostName,
                        subIdentifier: identifier.subIdentifier,
                        watchKitExtensionProductIdentifier:
                            watchKitExtensionProductIdentifier,
                        dependencySubIdentifiers: depSubIdentifiers
                    )
                )
        }

        return consolidationMaps
    }
}
