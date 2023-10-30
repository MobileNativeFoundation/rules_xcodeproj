import Foundation
import PBXProj

extension Generator {
    struct ReadTargetsFromConsolidationMaps {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.callable = callable
        }

        /// Reads consolidation maps from disk.
        func callAsFunction(
            _ urls: [URL],
            referencedContainer: String
        ) async throws -> [Target] {
            return try await callable(
                /*urls:*/ urls,
                /*referencedContainer:*/ referencedContainer
            )
        }
    }
}

// MARK: - ReadTargetsFromConsolidationMaps.Callable

extension Generator.ReadTargetsFromConsolidationMaps {
    typealias Callable = (
        _ urls: [URL],
        _ referencedContainer: String
    ) async throws -> [Target]

    static func defaultCallable(
        _ urls: [URL],
        referencedContainer: String
    ) async throws  -> [Target] {
        return try await withThrowingTaskGroup(
            of: [Target].self
        ) { group in
            for url in urls {
                group.addTask {
                    try await ConsolidationMapEntry.decode(from: url)
                        .map { entry in
                            return Target(
                                key: entry.key,
                                productType: entry.productType,
                                buildableReference: .init(
                                    blueprintIdentifier: Identifiers.Targets
                                        .idWithoutComment(
                                            subIdentifier: entry.subIdentifier,
                                            name: entry.name
                                        ),
                                    buildableName: String(
                                        entry.productPath
                                            .split(separator: "/").last!
                                    ),
                                    blueprintName: entry.name,
                                    referencedContainer: referencedContainer
                                )
                            )
                        }
                }
            }

            var targets: [Target] = []
            for try await shardTargets in group {
                targets.append(contentsOf: shardTargets)
            }

            return targets
        }
    }
}
