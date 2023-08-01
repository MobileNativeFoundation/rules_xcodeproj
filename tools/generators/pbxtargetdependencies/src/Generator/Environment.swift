import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let calculateConsolidationMaps: CalculateConsolidationMaps

        let calculateCreatedOnToolsVersion: CalculateCreatedOnToolsVersion

        let calculateTargetAttributesPartial: CalculateTargetAttributesPartial

        let calculateTargetDependenciesPartial:
            CalculateTargetDependenciesPartial

        let calculateTargetIdentifierMap: CalculateTargetIdentifierMap

        let calculateTargetsPartial: CalculateTargetsPartial

        let createDependencyObjects: CreateDependencyObjects

        let createTargetAttributesObjects: CreateTargetAttributesObjects

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
        calculateTargetAttributesPartial:
            Generator.CalculateTargetAttributesPartial(),
        calculateTargetDependenciesPartial:
            Generator.CalculateTargetDependenciesPartial(),
        calculateTargetIdentifierMap: Generator.CalculateTargetIdentifierMap(),
        calculateTargetsPartial: Generator.CalculateTargetsPartial(),
        createDependencyObjects: Generator.CreateDependencyObjects(
            createContainerItemProxyObject:
                Generator.CreateContainerItemProxyObject(),
            createTargetDependencyObject:
                Generator.CreateTargetDependencyObject()
        ),
        createTargetAttributesObjects: Generator.CreateTargetAttributesObjects(
            createTargetAttributesContent:
                Generator.CreateTargetAttributesContent()
        ),
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
