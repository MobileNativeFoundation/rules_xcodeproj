import Foundation
import GeneratorCommon

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let compatibilityVersion: (
            _ minimumXcodeVersion: SemanticVersion
        ) -> String

        let projectDir: (_ executionRoot: String) -> String

        let calculate: (
            _ compatibilityVersion: String,
            _ developmentRegion: String,
            _ organizationName: String?,
            _ projectDir: String,
            _ workspace: String
        ) -> String

        let readExecutionRootFile: (_ url: URL) throws -> String

        let write: (
            _ projectPrefix: String,
            _ outputPath: URL
        ) throws -> Void
    }
}

extension Generator.Environment {
    static let `default` = Self(
        compatibilityVersion: Generator.compatibilityVersion,
        projectDir: Generator.projectDir,
        calculate: Generator.calculate,
        readExecutionRootFile: Generator.readExecutionRootFile,
        write: Generator.write
    )
}
