import Foundation
import PBXProj

/// A type that generates and writes to disk a `PBXProject` prefix `PBXProj`
/// partial.
///
/// The `Generator` type is stateless. It can be used to generate multiple
/// partials. The `generate()` method is passed all the inputs needed to
/// generate a partial.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the `PBXProject` prefix `PBXProj` partial and writes it to
    /// disk.
    func generate(arguments: Arguments) throws {
        try environment.write(
            environment.calculate(
                /*compatibilityVersion:*/ environment
                    .compatibilityVersion(
                        arguments.minimumXcodeVersion
                    ),
                /*developmentRegion:*/ arguments.developmentRegion,
                /*organizationName:*/ arguments.organizationName,
                /*projectDir:*/ environment.projectDir(
                    /*executionRoot:*/ environment.readExecutionRootFile(
                        arguments.executionRootFile
                    )
                ),
                /*workspace:*/ arguments.workspace
            ),
            /*to:*/ arguments.outputPath
        )
    }
}
