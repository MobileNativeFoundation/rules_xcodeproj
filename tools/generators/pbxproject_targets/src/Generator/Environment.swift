import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let calculateConsolidationMaps: CalculateConsolidationMaps

        let calculateCreatedOnToolsVersion: CalculateCreatedOnToolsVersion

        let calculateTargetAttributes: CalculateTargetAttributes

        let calculateTargetAttributesPartial: CalculateTargetAttributesPartial

        let calculateTargetDependencies: CalculateTargetDependencies

        let calculateTargetDependenciesPartial:
            CalculateTargetDependenciesPartial

        let calculateTargetIdentifierMap: CalculateTargetIdentifierMap

        let calculateTargetsPartial: CalculateTargetsPartial

        let identifyTargets: IdentifyTargets

        let write: Write

        let writeConsolidationMaps: WriteConsolidationMaps
    }
}

extension Generator.Environment {
    static let `default` = Self(
        calculateConsolidationMaps: Generator.CalculateConsolidationMaps(),
        calculateCreatedOnToolsVersion:
            Generator.CalculateCreatedOnToolsVersion(),
        calculateTargetAttributes: Generator.CalculateTargetAttributes(
            calculateSingleTargetAttributes:
                Generator.CalculateSingleTargetAttributes()
        ),
        calculateTargetAttributesPartial:
            Generator.CalculateTargetAttributesPartial(),
        calculateTargetDependencies: Generator.CalculateTargetDependencies(
            calculateContainerItemProxy:
                Generator.CalculateContainerItemProxy(),
            calculateTargetDependency: Generator.CalculateTargetDependency()
        ),
        calculateTargetDependenciesPartial:
            Generator.CalculateTargetDependenciesPartial(),
        calculateTargetIdentifierMap: Generator.CalculateTargetIdentifierMap(),
        calculateTargetsPartial: Generator.CalculateTargetsPartial(),
        identifyTargets: Generator.IdentifyTargets(
            consolidateTargets: Generator.ConsolidateTargets(),
            disambiguateTargets: Generator.DisambiguateTargets(),
            innerIdentifyTargets: Generator.InnerIdentifyTargets(
                createTargetSubIdentifier: Generator.CreateTargetSubIdentifier()
            )
        ),
        write: Write(),
        writeConsolidationMaps: Generator.WriteConsolidationMaps(
            writeConsolidationMap: Generator.WriteConsolidationMap()
        )
    )
}
