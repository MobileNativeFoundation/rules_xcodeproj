import Foundation
import GeneratorCommon

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let buildSettings: (
            _ buildMode: BuildMode,
            _ indexingProjectDir: String,
            _ workspace: String
        ) -> String

        let compatibilityVersion: (
            _ minimumXcodeVersion: SemanticVersion
        ) -> String

        let indexingProjectDir: (_ projectDir: String) -> String

        let projectDir: (_ executionRoot: String) -> String

        let calculate: (
            _ buildSettings: String,
            _ compatibilityVersion: String,
            _ defaultXcodeConfiguration: String?,
            _ developmentRegion: String,
            _ organizationName: String?,
            _ projectDir: String,
            _ workspace: String,
            _ xcodeConfigurations: [String]
        ) -> String

        let readExecutionRootFile: (_ url: URL) throws -> String

        let write: (_ projectPrefix: String, _ outputPath: URL) throws -> Void
    }
}

extension Generator.Environment {
    static let `default` = Self(
        buildSettings: Generator.buildSettings,
        compatibilityVersion: Generator.compatibilityVersion,
        indexingProjectDir: Generator.indexingProjectDir,
        projectDir: Generator.projectDir,
        calculate: Generator.calculate,
        readExecutionRootFile: Generator.readExecutionRootFile,
        write: Generator.write
    )
}
