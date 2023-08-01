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
        let projectDir = environment.projectDir(
            /*executionRoot:*/ try environment.readExecutionRootFile(
                arguments.executionRootFile
            )
        )

        let bazelDependenciesPartial = environment.bazelDependenciesPartial(
            /*buildSettings:*/ environment
                .bazelDependenciesBuildSettings(
                    /*platforms:*/ arguments.platforms,
                    /*targetIdsFile:*/ arguments.targetIdsFile
                ),
            /*defaultXcodeConfiguration:*/ arguments
                .defaultXcodeConfiguration,
            /*postBuildRunScript:*/ environment.runScriptBuildPhase(
                /*name:*/ "Post-build",
                /*script:*/ try environment.readPrePostBuildScript(
                    /*postBuildScript:*/ arguments.postBuildScript
                )
            ),
            /*preBuildRunScript:*/ environment.runScriptBuildPhase(
                /*name:*/ "Pre-build",
                /*script:*/ try environment.readPrePostBuildScript(
                    /*preBuildScript:*/ arguments.preBuildScript
                )
            ),
            /*xcodeConfigurations:*/ arguments.xcodeConfigurations
        )

        let pbxProjectPrefixPartial = environment.pbxProjectPrefixPartial(
            /*buildSettings:*/ environment.pbxProjectBuildSettings(
                /*buildMode:*/ arguments.buildMode,
                /*indexImport:*/ arguments.indexImport,
                /*indexingProjectDir:*/ environment.indexingProjectDir(
                    /*projectDir:*/ projectDir
                ),
                /*projectDir:*/ projectDir,
                /*resolvedRepositories:*/
                    try environment.readResolvedRepositoriesFile(
                        arguments.resolvedRepositoriesFile
                    ),
                    /*workspace:*/ arguments.workspace,
                    /*createBuildSettingsAttribute:*/
                        environment.createBuildSettingsAttribute
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
        )

        try environment.write(
            environment.pbxProjPrefixPartial(
                /*bazelDependenciesPartial:*/ bazelDependenciesPartial,
                /*pbxProjectPrefixPartial:*/ pbxProjectPrefixPartial,
                /*minimumXcodeVersion:*/ arguments.minimumXcodeVersion
            ),
            to: arguments.outputPath
        )
    }
}
