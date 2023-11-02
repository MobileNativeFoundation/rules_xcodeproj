import Foundation
import PBXProj
import ToolCommon

struct IdentifiedTarget: Equatable {
    let consolidationMapOutputPath: URL
    let key: ConsolidatedTarget.Key
    let label: BazelLabel
    let productType: PBXProductType
    let name: String
    let productPath: String
    let productBasename: String
    let uiTestHostName: String?
    let identifier: Identifiers.Targets.Identifier
    let watchKitExtension: TargetID?
    let dependencies: [TargetID]
}

extension Generator {
    struct IdentifyTargets {
        private let consolidateTargets: ConsolidateTargets
        private let disambiguateTargets: DisambiguateTargets
        private let innerIdentifyTargets: InnerIdentifyTargets

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            consolidateTargets: ConsolidateTargets,
            disambiguateTargets: DisambiguateTargets,
            innerIdentifyTargets: InnerIdentifyTargets,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.consolidateTargets = consolidateTargets
            self.disambiguateTargets = disambiguateTargets
            self.innerIdentifyTargets = innerIdentifyTargets

            self.callable = callable
        }

        /// Identifies all the targets defined by the consolidation map
        /// arguments.
        func callAsFunction(
            consolidationMapArguments: [ConsolidationMapArguments],
            logger: Logger,
            targetNameMode: TargetNameMode
        ) throws -> [IdentifiedTarget] {
            return try callable(
                /*consolidationMapArguments:*/ consolidationMapArguments,
                /*logger:*/ logger,
                /*targetNameMode:*/ targetNameMode,
                /*consolidateTargets:*/ consolidateTargets,
                /*disambiguateTargets:*/ disambiguateTargets,
                /*innerIdentifyTargets:*/ innerIdentifyTargets
            )
        }
    }
}

// MARK: - IdentifyTargets.Callable

extension Generator.IdentifyTargets {
    public typealias Callable = (
        _ consolidationMapArguments: [ConsolidationMapArguments],
        _ logger: Logger,
        _ targetNameMode: TargetNameMode,
        _ consolidateTargets: Generator.ConsolidateTargets,
        _ disambiguateTargets: Generator.DisambiguateTargets,
        _ innerIdentifyTargets: Generator.InnerIdentifyTargets
    ) throws -> [IdentifiedTarget]

    // TODO: Add test
    static func defaultCallable(
        consolidationMapArguments: [ConsolidationMapArguments],
        logger: Logger,
        targetNameMode: TargetNameMode,
        consolidateTargets: Generator.ConsolidateTargets,
        disambiguateTargets: Generator.DisambiguateTargets,
        innerIdentifyTargets: Generator.InnerIdentifyTargets
    ) throws -> [IdentifiedTarget] {
        var targets: [Target] = []
        var targetIdToOutputPathKeysWithValues: [(TargetID, (UInt8, URL))] = []
        for (shard, args) in consolidationMapArguments.enumerated() {
            targets.append(contentsOf: args.targets)
            args.targets.forEach { target in
                targetIdToOutputPathKeysWithValues.append(
                    (target.id, (UInt8(shard), args.outputPath))
                )
            }
        }
        let targetIdToOutputPath =
            Dictionary(uniqueKeysWithValues: targetIdToOutputPathKeysWithValues)

        return try innerIdentifyTargets(
            disambiguateTargets(
                consolidateTargets(targets, logger: logger),
                targetNameMode: targetNameMode
            ),
            targetIdToConsolidationMapOutputPath: targetIdToOutputPath
        )
    }
}
