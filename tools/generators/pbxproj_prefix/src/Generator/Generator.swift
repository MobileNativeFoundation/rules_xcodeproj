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
        let projectDir = try environment.projectDir(
            /* executionRoot: */ environment.readExecutionRootFile(
                arguments.executionRootFile
            )
        )

        let bazelDependenciesPartial = try environment.bazelDependenciesPartial(
            /* buildSettings: */ environment
                .bazelDependenciesBuildSettings(
                    /* platforms: */ arguments.platforms,
                    /* targetIdsFile: */ arguments.targetIdsFile
                ),
            /* defaultXcodeConfiguration: */ arguments
                .defaultXcodeConfiguration,
            /* postBuildRunScript: */ environment.runScriptBuildPhase(
                /* name: */ "Post-build",
                /* script: */ environment.readPrePostBuildScript(
                    /* postBuildScript: */ arguments.postBuildScript
                )
            ),
            /* preBuildRunScript: */ environment.runScriptBuildPhase(
                /* name: */ "Pre-build",
                /* script: */ environment.readPrePostBuildScript(
                    /* preBuildScript: */ arguments.preBuildScript
                )
            ),
            /* xcodeConfigurations: */ arguments.xcodeConfigurations
        )

        let resolvedRepositories = try environment.readResolvedRepositoriesFile(
            arguments.resolvedRepositoriesFile
        )
        let buildSettings = Dictionary(uniqueKeysWithValues:
            arguments.xcodeConfigurations.map { configuration in
                (configuration, environment.pbxProjectBuildSettings(
                    /* config: */ arguments.config,
                    /* createBuildSettingsAttribute: */
                        environment.createBuildSettingsAttribute,
                    /* importIndexBuildIndexstores: */ arguments
                        .importIndexBuildIndexstores,
                    /* indexImport: */ arguments.indexImport,
                    /* indexingProjectDir: */ environment.indexingProjectDir(
                        /* projectDir: */ projectDir
                    ),
                    /* legacyIndexImport: */ arguments.legacyIndexImport,
                    /* nativePreviews: */ arguments.previewXcodeConfigurations
                        .contains(configuration),
                    /* projectDir: */ projectDir,
                    /* resolvedRepositories: */ resolvedRepositories,
                    /* separateIndexBuildOutputBase: */ arguments
                        .separateIndexBuildOutputBase,
                    /* suppressCoverageBuild: */ arguments.suppressCoverageBuild,
                    /* workspace: */ arguments.workspace
                ))
            })
        let pbxProjectPrefixPartial = environment.pbxProjectPrefixPartial(
            /* buildSettings: */ buildSettings,
            /* compatibilityVersion: */ environment.compatibilityVersion(
                arguments.minimumXcodeVersion
            ),
            /* defaultXcodeConfiguration: */ arguments
                .defaultXcodeConfiguration,
            /* developmentRegion: */ arguments.developmentRegion,
            /* organizationName: */ arguments.organizationName,
            /* projectDir: */ projectDir,
            /* workspace: */ arguments.workspace,
            /* xcodeConfigurations: */ arguments.xcodeConfigurations
        )

        try environment.write(
            environment.pbxProjPrefixPartial(
                /* bazelDependenciesPartial: */ bazelDependenciesPartial,
                /* pbxProjectPrefixPartial: */ pbxProjectPrefixPartial,
                /* minimumXcodeVersion: */ arguments.minimumXcodeVersion
            ),
            to: arguments.outputPath
        )
    }
}
