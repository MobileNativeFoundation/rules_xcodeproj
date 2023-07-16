import Foundation
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
            identifiers: [TargetID: Identifiers.Targets.Identifier]
        ) throws -> [URL: [ConsolidationMapEntry]] {
            return try callable(
                /*identifiedTargets:*/ identifiedTargets,
                /*identifiers:*/ identifiers
            )
        }
    }
}

// MARK: - CalculateConsolidationMaps.Callable

extension Generator.CalculateConsolidationMaps {
    typealias Callable = (
        _ identifiedTargets: [IdentifiedTarget],
        _ identifiers: [TargetID: Identifiers.Targets.Identifier]
    ) throws -> [URL: [ConsolidationMapEntry]]

    static func defaultCallable(
        identifiedTargets: [IdentifiedTarget],
        identifiers: [TargetID: Identifiers.Targets.Identifier]
    ) throws -> [URL: [ConsolidationMapEntry]] {
        var consolidationMaps: [URL: [ConsolidationMapEntry]] = [:]
        for target in identifiedTargets {
            let identifier = target.identifier

            var depSubIdentifiers: [Identifiers.Targets.SubIdentifier] = [
                .bazelDependencies,
            ]
            depSubIdentifiers
                .append(contentsOf: try target.dependencies.map { id in
                    return try identifiers
                        .value(for: id ,context: "Dependency")
                        .subIdentifier
                })

            consolidationMaps[target.consolidationMapOutputPath, default: []]
                .append(
                    ConsolidationMapEntry(
                        key: target.key,
                        name: target.name,
                        subIdentifier: identifier.subIdentifier,
                        dependencySubIdentifiers: depSubIdentifiers
                    )
                )
        }

        return consolidationMaps
    }
}
