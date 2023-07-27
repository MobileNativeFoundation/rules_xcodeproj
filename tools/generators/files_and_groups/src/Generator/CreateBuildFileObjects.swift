import Foundation
import PBXProj

extension Generator {
    struct CreateBuildFileObjects {
        private let createShardBuildFileObjects: CreateShardBuildFileObjects

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createShardBuildFileObjects: CreateShardBuildFileObjects,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createShardBuildFileObjects = createShardBuildFileObjects

            self.callable = callable
        }

        /// Reads `[Identifiers.BuildFile.SubIdentifier]` from disk.
        func callAsFunction(
            buildFileSubIdentifierFiles: [URL],
            fileIdentifiersTask: Task<[BazelPath: String], Error>
        ) async throws -> [Object] {
            try await callable(
                /*buildFileSubIdentifierFiles:*/ buildFileSubIdentifierFiles,
                /*fileIdentifiersTask:*/ fileIdentifiersTask,
                /*createShardBuildFileObjects:*/ createShardBuildFileObjects
            )
        }
    }
}

// MARK: - CreateBuildFileObjects.Callable

extension Generator.CreateBuildFileObjects {
    typealias Callable = (
        _ buildFileSubIdentifierFiles: [URL],
        _ fileIdentifiersTask: Task<[BazelPath: String], Error>,
        _ createShardBuildFileObjects: Generator.CreateShardBuildFileObjects
    ) async throws -> [Object]

    static func defaultCallable(
        buildFileSubIdentifierFiles: [URL],
        fileIdentifiersTask: Task<[BazelPath: String], Error>,
        createShardBuildFileObjects: Generator.CreateShardBuildFileObjects
    ) async throws -> [Object] {
        return try await withThrowingTaskGroup(
            of: [Object].self
        ) { group in
            for buildFileSubIdentifierFile in buildFileSubIdentifierFiles {
                group.addTask {
                    return try await createShardBuildFileObjects(
                        buildFileSubIdentifierFile: buildFileSubIdentifierFile,
                        fileIdentifiersTask: fileIdentifiersTask
                    )
                }
            }

            var buildFileElements: [Object] = []
            for try await shardObjects in group {
                buildFileElements.append(contentsOf: shardObjects)
            }

            return buildFileElements
        }
    }
}
