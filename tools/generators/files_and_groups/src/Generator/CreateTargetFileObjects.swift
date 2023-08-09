import Foundation
import PBXProj

extension Generator {
    struct CreateTargetFileObjects {
        private let createShardTargetFileObjects: CreateShardTargetFileObjects

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createShardTargetFileObjects: CreateShardTargetFileObjects,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createShardTargetFileObjects = createShardTargetFileObjects

            self.callable = callable
        }

        /// Reads `[Identifiers.BuildFile.SubIdentifier]` from disk.
        func callAsFunction(
            buildFileSubIdentifierFiles: [URL],
            fileIdentifiersTask: Task<[BazelPath: String], Error>
        ) async throws -> [TargetFileObject] {
            try await callable(
                /*buildFileSubIdentifierFiles:*/ buildFileSubIdentifierFiles,
                /*fileIdentifiersTask:*/ fileIdentifiersTask,
                /*createShardTargetFileObjects:*/ createShardTargetFileObjects
            )
        }
    }
}

// MARK: - CreateTargetFileObjects.Callable

extension Generator.CreateTargetFileObjects {
    typealias Callable = (
        _ buildFileSubIdentifierFiles: [URL],
        _ fileIdentifiersTask: Task<[BazelPath: String], Error>,
        _ createShardTargetFileObjects: Generator.CreateShardTargetFileObjects
    ) async throws -> [TargetFileObject]

    static func defaultCallable(
        buildFileSubIdentifierFiles: [URL],
        fileIdentifiersTask: Task<[BazelPath: String], Error>,
        createShardTargetFileObjects: Generator.CreateShardTargetFileObjects
    ) async throws -> [TargetFileObject] {
        return try await withThrowingTaskGroup(
            of: [TargetFileObject].self
        ) { group in
            for buildFileSubIdentifierFile in buildFileSubIdentifierFiles {
                group.addTask {
                    return try await createShardTargetFileObjects(
                        buildFileSubIdentifierFile: buildFileSubIdentifierFile,
                        fileIdentifiersTask: fileIdentifiersTask
                    )
                }
            }

            var objects: [TargetFileObject] = []
            for try await shardObjects in group {
                objects.append(contentsOf: shardObjects)
            }

            return objects
        }
    }
}
