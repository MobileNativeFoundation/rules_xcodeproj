import Foundation
import PBXProj

extension Generator {
    struct InnerIdentifyTargets {
        private let createTargetSubIdentifier: CreateTargetSubIdentifier

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createTargetSubIdentifier: CreateTargetSubIdentifier,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createTargetSubIdentifier = createTargetSubIdentifier

            self.callable = callable
        }

        /// Identifies a set of disambiguated targets.
        func callAsFunction(
            _ disambiguatedTargets: [DisambiguatedTarget],
            targetIdToConsolidationMapOutputPath: [TargetID : (UInt8, URL)]
        ) -> [IdentifiedTarget] {
            return callable(
                /*disambiguatedTargets:*/ disambiguatedTargets,
                /*targetIdToConsolidationMapOutputPath:*/
                    targetIdToConsolidationMapOutputPath,
                /*createTargetSubIdentifier:*/ createTargetSubIdentifier
            )
        }
    }
}

// MARK: - InnerIdentifyTargets.Callable

extension Generator.InnerIdentifyTargets {
    public typealias Callable = (
        _ disambiguatedTargets: [DisambiguatedTarget],
        _ targetIdToConsolidationMapOutputPath: [TargetID : (UInt8, URL)],
        _ createTargetSubIdentifier: Generator.CreateTargetSubIdentifier
    ) -> [IdentifiedTarget]

    static func defaultCallable(
        _ disambiguatedTargets: [DisambiguatedTarget],
        targetIdToConsolidationMapOutputPath: [TargetID : (UInt8, URL)],
        createTargetSubIdentifier: Generator.CreateTargetSubIdentifier
    ) -> [IdentifiedTarget] {
        let idsToNames: [TargetID: String] = Dictionary(
            uniqueKeysWithValues: disambiguatedTargets.lazy.flatMap { target in
                return target.target.key.sortedIds.map { id in
                    return (id, target.name)
                }
            }
        )

        var identifiedTargets: [IdentifiedTarget] = []
        for disambiguatedTarget in disambiguatedTargets {
            let aTarget = disambiguatedTarget.target.sortedTargets.first!
            let id = aTarget.id
            let (shard, outputPath) = targetIdToConsolidationMapOutputPath[id]!

            let identifier = Identifiers.Targets.id(
                subIdentifier: createTargetSubIdentifier(
                    id,
                    shard: shard
                ),
                name: disambiguatedTarget.name
            )

            identifiedTargets.append(
                IdentifiedTarget(
                    consolidationMapOutputPath: outputPath,
                    key: disambiguatedTarget.target.key,
                    label: disambiguatedTarget.target.label,
                    productType: disambiguatedTarget.target.productType,
                    name: disambiguatedTarget.name,
                    productPath: aTarget.productPath,
                    productBasename: aTarget.productBasename,
                    uiTestHostName: disambiguatedTarget
                        .target.uiTestHost.flatMap { idsToNames[$0] },
                    identifier: identifier,
                    watchKitExtension: aTarget.watchKitExtension,
                    dependencies: aTarget.dependencies
                )
            )
        }

        return identifiedTargets
    }
}
