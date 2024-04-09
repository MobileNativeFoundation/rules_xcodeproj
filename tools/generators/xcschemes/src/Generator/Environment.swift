import PBXProj
import XCScheme

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let calculateSchemeReferencedContainer:
            CalculateSchemeReferencedContainer

        let calculateTargetsByKey: CalculateTargetsByKey

        let createAutomaticSchemeInfos: CreateAutomaticSchemeInfos

        let createCustomSchemeInfos: CreateCustomSchemeInfos

        let readExtensionPointIdentifiersFile: ReadExtensionPointIdentifiersFile

        let readTargetArgsAndEnvFile: ReadTargetArgsAndEnvFile

        let readTargetsFromConsolidationMaps: ReadTargetsFromConsolidationMaps

        let writeSchemeManagement: WriteSchemeManagement

        let writeSchemes: WriteSchemes
    }
}

extension Generator.Environment {
    static let `default` = Self(
        calculateSchemeReferencedContainer:
            Generator.CalculateSchemeReferencedContainer(),
        calculateTargetsByKey: Generator.CalculateTargetsByKey(),
        createAutomaticSchemeInfos: Generator.CreateAutomaticSchemeInfos(
            createTargetAutomaticSchemeInfos:
                Generator.CreateTargetAutomaticSchemeInfos(
                    createAutomaticSchemeInfo:
                        Generator.CreateAutomaticSchemeInfo()
                )
        ),
        createCustomSchemeInfos: Generator.CreateCustomSchemeInfos(),
        readExtensionPointIdentifiersFile:
            Generator.ReadExtensionPointIdentifiersFile(),
        readTargetArgsAndEnvFile: Generator.ReadTargetArgsAndEnvFile(),
        readTargetsFromConsolidationMaps:
            Generator.ReadTargetsFromConsolidationMaps(),
        writeSchemeManagement: Generator.WriteSchemeManagement(
            createSchemeManagement: CreateSchemeManagement(),
            write: Write()
        ),
        writeSchemes: Generator.WriteSchemes(
            createScheme: Generator.CreateScheme(
                createAnalyzeAction: CreateAnalyzeAction(),
                createArchiveAction: CreateArchiveAction(),
                createBuildAction: CreateBuildAction(),
                createLaunchAction: CreateLaunchAction(),
                createProfileAction: CreateProfileAction(),
                createSchemeXML: XCScheme.CreateScheme(),
                createTestAction: CreateTestAction()
            ),
            write: Write()
        )
    )
}
