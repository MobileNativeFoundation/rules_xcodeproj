import Foundation
import GeneratorCommon
import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let buildSettings: (
            _ indexImport: String,
            _ platforms: [Platform],
            _ targetIdsFile: String
        ) -> String

        let calculate: (
            _ buildConfigurationContent: String,
            _ defaultXcodeConfiguration: String?,
            _ preBuildRunScript: String?,
            _ postBuildRunScript: String?,
            _ xcodeConfigurations: [String]
        ) -> String

        let readPrePostBuildScript: (_ url: URL?) throws -> String?

        let runScriptBuildPhase: (_ name: String, _ script: String?) -> String?

        let write: (
            _ bazelDependencies: String,
            _ outputPath: URL
        ) throws -> Void
    }
}

extension Generator.Environment {
    static let `default` = Self(
        buildSettings: Generator.buildSettings,
        calculate: Generator.calculate,
        readPrePostBuildScript: Generator.readPrePostBuildScript,
        runScriptBuildPhase: Generator.runScriptBuildPhase,
        write: Generator.write
    )
}
