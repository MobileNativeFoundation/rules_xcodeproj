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
        let buildableFolders = try await environment.readBuildableFoldersFile(
            arguments.buildableFoldersFile
        )

        // FIXME: Do these in parallel as tasks
        let pathTree = try await environment.calculatePathTree(
            /* paths: */
                environment.readFilePathsFile(arguments.filePathsFile)
                    .filter { !$0.isContained(in: buildableFolders) },
            /* generatedPaths: */ environment.readGeneratedFilePathsFile(
                arguments.generatedFilePathsFile
            ),
            /* buildableFolders: */ buildableFolders
        )

        let elementsCreator = ElementCreator(environment: environment.elements)

        let createElementsTask = Task {
            return try elementsCreator.create(
                pathTree: pathTree,
                arguments: arguments.elementCreatorArguments,
                compileStubNeeded: arguments.compileStubNeeded
            )
        }

        let writeKnownRegionsPartialTask = Task {
            return try await environment.write(
                environment.knownRegionsPartial(
                    /* knownRegions: */
                        createElementsTask.value.knownRegions,
                    /* developmentRegion: */ arguments.developmentRegion,
                    /* useBaseInternationalization: */
                    arguments.useBaseInternationalization
                ),
                to: arguments.knownRegionsOutputPath
            )
        }

        let writeFilesAndGroupsPartialTask = Task {
            let buildFilesPartial = try await environment.calculateTargetFilesPartial(
                objects: environment.createTargetFileObjects(
                    buildFileSubIdentifierFiles:
                        arguments.buildFileSubIdentifiersFiles,
                    // Because we pass in a task here,
                    // `createTargetFileObjects()` can start before
                    // `elementsCreator.create()` has finished. This allows
                    // `createTargetFileObjects()` to read in all of
                    // `buildFileSubIdentifiersFiles` and then block on
                    // `fileIdentifiers` being created.
                    fileIdentifiersTask: Task {
                        let createdElements = try await createElementsTask.value
                        return Dictionary(
                            uniqueKeysWithValues:
                                createdElements.bazelPathAndIdentifiers
                        )
                    }
                )
            )

            return try await environment.write(
                environment.filesAndGroupsPartial(
                    /* buildFilesPartial: */ buildFilesPartial,
                    /* elementsPartial: */
                        createElementsTask.value.partial
                ),
                to: arguments.filesAndGroupsOutputPath
            )
        }

        let writeResolvedRepositoriesBuildSettingTask = Task {
            return try await environment.write(
                environment.resolvedRepositoriesBuildSetting(
                    /* resolvedRepositories: */
                        createElementsTask.value.resolvedRepositories
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
