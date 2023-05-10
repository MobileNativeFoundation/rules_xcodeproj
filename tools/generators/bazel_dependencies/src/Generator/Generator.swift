import Foundation
import PBXProj

/// A type that generates and writes to disk a BazelDependencies `PBXProj`
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

    /// Calculates the BazelDependencies `PBXProj` partial and writes it to
    /// disk
    func generate(arguments: Arguments) throws {
        try environment.write(
            environment.calculate(
                /*buildSettings:*/ environment
                    .buildSettings(
                        /*indexImport:*/ arguments.indexImport,
                        /*platforms:*/ arguments.platforms,
                        /*targetIdsFile:*/ arguments.targetIdsFile
                    ),
                /*defaultXcodeConfiguration:*/ arguments
                    .defaultXcodeConfiguration,
                /*postBuildRunScript:*/ environment.runScriptBuildPhase(
                    /*name:*/ "Post-build",
                    /*script:*/ environment.readPrePostBuildScript(
                        /*postBuildScript:*/ arguments.postBuildScript
                    )
                ),
                /*preBuildRunScript:*/ environment.runScriptBuildPhase(
                    /*name:*/ "Pre-build",
                    /*script:*/ environment.readPrePostBuildScript(
                        /*preBuildScript:*/ arguments.preBuildScript
                    )
                ),
                /*xcodeConfigurations:*/ arguments.xcodeConfigurations
             ),
             /*to:*/ arguments.outputPath
         )
    }
}
