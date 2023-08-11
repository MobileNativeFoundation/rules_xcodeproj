import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let calculatePartial: CalculatePartial

        let calculatePlatformVariantBuildSettings:
            CalculatePlatformVariantBuildSettings

        let calculateSharedBuildSettings: CalculateSharedBuildSettings

        let calculateXcodeConfigurationBuildSettings:
            CalculateXcodeConfigurationBuildSettings

        let createBazelIntegrationBuildPhaseObject:
            CreateBazelIntegrationBuildPhaseObject

        let createBuildConfigurationObject: CreateBuildConfigurationObject

        let createBuildConfigurationListObject:
            CreateBuildConfigurationListObject

        let createBuildFileSubIdentifier: CreateBuildFileSubIdentifier

        let createBuildSettingsAttribute: CreateBuildSettingsAttribute

        let createCreateCompileDependenciesBuildPhaseObject:
            CreateCreateCompileDependenciesBuildPhaseObject

        let createCreateLinkDependenciesBuildPhaseObject:
            CreateCreateLinkDependenciesBuildPhaseObject

        let createEmbedAppExtensionsBuildPhaseObject:
            CreateEmbedAppExtensionsBuildPhaseObject

        let createHeadersBuildPhaseObject: CreateHeadersBuildPhaseObject

        let createProductObject: CreateProductObject

        let createSourcesBuildPhaseObject: CreateSourcesBuildPhaseObject

        let createTargetObject: CreateTargetObject

        let write: Write

        let writeBuildFileSubIdentifiers: WriteBuildFileSubIdentifiers
    }
}

extension Generator.Environment {
    static let `default` = Self(
        calculatePartial: Generator.CalculatePartial(),
        calculatePlatformVariantBuildSettings:
            Generator.CalculatePlatformVariantBuildSettings(),
        calculateSharedBuildSettings: Generator.CalculateSharedBuildSettings(),
        calculateXcodeConfigurationBuildSettings:
            Generator.CalculateXcodeConfigurationBuildSettings(),
        createBazelIntegrationBuildPhaseObject:
            Generator.CreateBazelIntegrationBuildPhaseObject(),
        createBuildConfigurationObject:
            Generator.CreateBuildConfigurationObject(),
        createBuildConfigurationListObject:
            Generator.CreateBuildConfigurationListObject(),
        createBuildFileSubIdentifier: Generator.CreateBuildFileSubIdentifier(),
        createBuildSettingsAttribute: CreateBuildSettingsAttribute(),
        createCreateCompileDependenciesBuildPhaseObject:
            Generator.CreateCreateCompileDependenciesBuildPhaseObject(),
        createCreateLinkDependenciesBuildPhaseObject:
            Generator.CreateCreateLinkDependenciesBuildPhaseObject(),
        createEmbedAppExtensionsBuildPhaseObject:
            Generator.CreateEmbedAppExtensionsBuildPhaseObject(),
        createHeadersBuildPhaseObject:
            Generator.CreateHeadersBuildPhaseObject(),
        createProductObject: Generator.CreateProductObject(),
        createSourcesBuildPhaseObject:
            Generator.CreateSourcesBuildPhaseObject(),
        createTargetObject: Generator.CreateTargetObject(),
        write: Write(),
        writeBuildFileSubIdentifiers: Generator.WriteBuildFileSubIdentifiers()
    )
}
