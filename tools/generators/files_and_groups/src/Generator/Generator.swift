import Foundation
import PBXProj

/// A type that generates and writes to disk the `PBXProject.knownRegions`
/// `PBXProj` partial, files and groups `PBXProj` partial, and
/// `RESOLVED_REPOSITORIES` build setting.
///
/// The `Generator` type is stateless. It can be used to generate multiple
/// partials. The `generate()` method is passed all the inputs needed to
/// generate a partial.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the `PBXProject.knownRegions` `PBXProj` partial, files and
    /// groups `PBXProj` partial, and `RESOLVED_REPOSITORIES` build setting.
    /// Then it writes them to disk.
    func generate(arguments: Arguments) async throws {
        let pathTree = environment.calculatePathTree(
            /*paths:*/ Set(arguments.filePaths + arguments.folderPaths)
        )

        let elementsCreator = ElementCreator(environment: environment.elements)

        let (
            elementsPartial,
            knownRegions,
            resolvedRepositories
        ) = try elementsCreator.create(
            pathTree: pathTree,
            arguments: arguments.elementCreatorArguments
        )

        let writeKnownRegionsPartialTask = Task {
            try environment.write(
                environment.knownRegionsPartial(
                    /*knownRegions:*/ knownRegions,
                                      /*developmentRegion:*/ arguments.developmentRegion,
                                      /*useBaseInternationalization:*/
                                      arguments.useBaseInternationalization
                ),
                to: arguments.knownRegionsOutputPath
            )
        }

        let writeFilesAndGroupsPartialTask = Task {
            try environment.write(
                environment.filesAndGroupsPartial(
                    /*elementsPartial:*/ elementsPartial
                ),
                to: arguments.filesAndGroupsOutputPath
            )
        }

        let writeResolvedRepositoriesBuildSettingTask = Task {
            try environment.write(
                environment.resolvedRepositoriesBuildSetting(
                    /*resolvedRepositories:*/ resolvedRepositories
                ),
                to: arguments.resolvedRepositoriesOutputPath
            )
        }

        // Wait for all of the writes to complete
        try await writeFilesAndGroupsPartialTask.value
        try await writeKnownRegionsPartialTask.value
        try await writeResolvedRepositoriesBuildSettingTask.value
    }
}
