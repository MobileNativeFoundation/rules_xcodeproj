import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let calculatePartial: CalculatePartial
        let createTarget: CreateTarget
        let write: Write
        let writeBuildFileSubIdentifiers: WriteBuildFileSubIdentifiers
    }
}

extension Generator.Environment {
    static let `default` = Self(
        calculatePartial: Generator.CalculatePartial(),
        createTarget: Generator.CreateTarget(
            calculatePlatformVariants: Generator.CalculatePlatformVariants(),
            createBuildPhases: Generator.CreateBuildPhases(
                createBazelIntegrationBuildPhaseObject:
                    Generator.CreateBazelIntegrationBuildPhaseObject(),
                createBuildFileSubIdentifier:
                    Generator.CreateBuildFileSubIdentifier(),
                createCreateCompileDependenciesBuildPhaseObject:
                    Generator.CreateCreateCompileDependenciesBuildPhaseObject(),
                createCreateLinkDependenciesBuildPhaseObject:
                    Generator.CreateCreateLinkDependenciesBuildPhaseObject(),
                createEmbedAppExtensionsBuildPhaseObject:
                    Generator.CreateEmbedAppExtensionsBuildPhaseObject(),
                createProductBuildFileObject:
                    Generator.CreateProductBuildFileObject(),
                createSourcesBuildPhaseObject:
                    Generator.CreateSourcesBuildPhaseObject(),
                createLinkBinaryWithLibrariesBuildPhaseObject:
                    Generator.CreateLinkBinaryWithLibrariesBuildPhaseObject(),
                createFrameworkObject: Generator.CreateFrameworkObject(),
                createFrameworkBuildFileObject:
                    Generator.CreateFrameworkBuildFileObject()
            ),
            createProductObject: Generator.CreateProductObject(),
            createTargetObject: Generator.CreateTargetObject(),
            createXcodeConfigurations: Generator.CreateXcodeConfigurations(
                calculatePlatformVariantBuildSettings:
                    Generator.CalculatePlatformVariantBuildSettings(),
                calculateSharedBuildSettings:
                    Generator.CalculateSharedBuildSettings(),
                calculateXcodeConfigurationBuildSettings:
                    Generator.CalculateXcodeConfigurationBuildSettings(),
                createBuildConfigurationListObject:
                    Generator.CreateBuildConfigurationListObject(),
                createBuildConfigurationObject:
                    Generator.CreateBuildConfigurationObject(),
                createBuildSettingsAttribute: CreateBuildSettingsAttribute()
            )
        ),
        write: Write(),
        writeBuildFileSubIdentifiers: Generator.WriteBuildFileSubIdentifiers()
    )
}
