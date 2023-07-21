import Foundation
import GeneratorCommon
import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let bazelDependenciesBuildSettings: (
            _ platforms: [Platform],
            _ targetIdsFile: String
        ) -> String

        let bazelDependenciesPartial: (
            _ buildConfigurationContent: String,
            _ defaultXcodeConfiguration: String,
            _ preBuildRunScript: String?,
            _ postBuildRunScript: String?,
            _ xcodeConfigurations: [String]
        ) -> String

        let createBuildSettingsAttribute: CreateBuildSettingsAttribute

        let compatibilityVersion: (
            _ minimumXcodeVersion: SemanticVersion
        ) -> String

        let indexingProjectDir: (_ projectDir: String) -> String

        let pbxProjectBuildSettings: (
            _ buildMode: BuildMode,
            _ indexImport: String,
            _ indexingProjectDir: String,
            _ projectDir: String,
            _ resolvedRepositories: String,
            _ workspace: String,
            _ createBuildSettingsAttribute: CreateBuildSettingsAttribute
        ) -> String

        let pbxProjectPrefixPartial: (
            _ buildSettings: String,
            _ compatibilityVersion: String,
            _ defaultXcodeConfiguration: String,
            _ developmentRegion: String,
            _ organizationName: String?,
            _ projectDir: String,
            _ workspace: String,
            _ xcodeConfigurations: [String]
        ) -> String

        let pbxProjPrefixPartial: (
            _ bazelDependenciesPartial: String,
            _ pbxProjectPrefixPartial: String,
            _ xcodeVersion: SemanticVersion
        ) -> String

        let projectDir: (_ executionRoot: String) -> String

        let readExecutionRootFile: (_ url: URL) throws -> String

        let readResolvedRepositoriesFile: (_ url: URL) throws -> String

        let readPrePostBuildScript: (_ url: URL?) throws -> String?

        let runScriptBuildPhase: (_ name: String, _ script: String?) -> String?

        let write: Write
    }
}

extension Generator.Environment {
    static let `default` = Self(
        bazelDependenciesBuildSettings:
            Generator.bazelDependenciesBuildSettings,
        bazelDependenciesPartial: Generator.bazelDependenciesPartial,
        createBuildSettingsAttribute: CreateBuildSettingsAttribute(),
        compatibilityVersion: Generator.compatibilityVersion,
        indexingProjectDir: Generator.indexingProjectDir,
        pbxProjectBuildSettings: Generator.pbxProjectBuildSettings,
        pbxProjectPrefixPartial: Generator.pbxProjectPrefixPartial,
        pbxProjPrefixPartial: Generator.pbxProjPrefixPartial,
        projectDir: Generator.projectDir,
        readExecutionRootFile: Generator.readExecutionRootFile,
        readResolvedRepositoriesFile: Generator.readResolvedRepositoriesFile,
        readPrePostBuildScript: Generator.readPrePostBuildScript,
        runScriptBuildPhase: Generator.runScriptBuildPhase,
        write: Write()
    )
}
