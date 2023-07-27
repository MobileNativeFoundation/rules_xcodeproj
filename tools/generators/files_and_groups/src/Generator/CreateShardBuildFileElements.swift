import Foundation
import PBXProj

extension Generator {
    struct CreateShardBuildFileObjects {
        private let createBuildFileObject: Generator.CreateBuildFileObject
        private let readBuildFileSubIdentifiersFile:
            ReadBuildFileSubIdentifiersFile

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createBuildFileObject: Generator.CreateBuildFileObject,
            readBuildFileSubIdentifiersFile: ReadBuildFileSubIdentifiersFile,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createBuildFileObject = createBuildFileObject
            self.readBuildFileSubIdentifiersFile =
                readBuildFileSubIdentifiersFile

            self.callable = callable
        }

        /// Creates `PBXBuildFile` elements by reading the
        /// `Identifiers.BuildFile.SubIdentifier`s from a file and matching them
        /// with file identifiers.
        func callAsFunction(
            buildFileSubIdentifierFile: URL,
            fileIdentifiersTask: Task<[BazelPath: String], Error>
        ) async throws -> [Object] {
            return try await callable(
                /*buildFileSubIdentifierFile:*/ buildFileSubIdentifierFile,
                /*fileIdentifiersTask:*/ fileIdentifiersTask,
                /*createBuildFileObject:*/ createBuildFileObject,
                /*readBuildFileSubIdentifiersFile:*/
                    readBuildFileSubIdentifiersFile
            )
        }
    }
}

// MARK: - CreateShardBuildFileObjects.Callable

extension Generator.CreateShardBuildFileObjects {
    typealias Callable = (
        _ buildFileSubIdentifierFile: URL,
        _ fileIdentifiersTask: Task<[BazelPath: String], Error>,
        _ createBuildFileObject: Generator.CreateBuildFileObject,
        _ readBuildFileSubIdentifiersFile:
            Generator.ReadBuildFileSubIdentifiersFile
    ) async throws -> [Object]

    static func defaultCallable(
        buildFileSubIdentifierFile: URL,
        fileIdentifiersTask: Task<[BazelPath: String], Error>,
        createBuildFileObject: Generator.CreateBuildFileObject,
        readBuildFileSubIdentifiersFile:
            Generator.ReadBuildFileSubIdentifiersFile
    ) async throws -> [Object] {
        let subIdentifiers = try await
            readBuildFileSubIdentifiersFile(buildFileSubIdentifierFile)

        let fileIdentifiers = try await fileIdentifiersTask.value

        return try subIdentifiers.map { subIdentifier in
            return createBuildFileObject(
                subIdentifier: subIdentifier,
                fileIdentifier: try fileIdentifiers.value(
                    for: subIdentifier.path,
                    context: "Path"
                )
            )
        }
    }
}
