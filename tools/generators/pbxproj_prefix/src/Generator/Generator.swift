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
    /// disk
    func generate(arguments: Arguments) throws {
        let projectDir = environment.projectDir(
            /*executionRoot:*/ try environment.readExecutionRootFile(
                arguments.executionRootFile
            )
        )

        try environment.write(
            environment.calculate(
                /*buildSettings:*/ environment.buildSettings(
                    /*buildMode:*/ arguments.buildMode,
                    /*indexingProjectDir:*/ environment.indexingProjectDir(
                        /*projectDir:*/ projectDir
                    ),
                    /*workspace:*/ arguments.workspace
                ),
                /*compatibilityVersion:*/ environment.compatibilityVersion(
                    arguments.minimumXcodeVersion
                ),
                /*defaultXcodeConfiguration:*/ arguments
                    .defaultXcodeConfiguration,
                /*developmentRegion:*/ arguments.developmentRegion,
                /*organizationName:*/ arguments.organizationName,
                /*projectDir:*/ projectDir,
                /*workspace:*/ arguments.workspace,
                /*xcodeConfigurations:*/ arguments.xcodeConfigurations
            ),
            /*to:*/ arguments.outputPath
        )
    }
}
