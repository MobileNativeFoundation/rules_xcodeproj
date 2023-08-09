import Foundation
import PBXProj

extension Generator {
    struct CreateShardTargetFileObjects {
        private let createBuildFileObject: CreateBuildFileObject
        private let readBuildFileSubIdentifiersFile:
            ReadBuildFileSubIdentifiersFile

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createBuildFileObject: CreateBuildFileObject,
            readBuildFileSubIdentifiersFile: ReadBuildFileSubIdentifiersFile,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createBuildFileObject = createBuildFileObject
            self.readBuildFileSubIdentifiersFile =
                readBuildFileSubIdentifiersFile

            self.callable = callable
        }

        /// Creates `PBXBuildFile` objects by reading the
        /// `Identifiers.BuildFile.SubIdentifier`s from a file and matching them
        /// with file identifiers.
        func callAsFunction(
            buildFileSubIdentifierFile: URL,
            fileIdentifiersTask: Task<[BazelPath: String], Error>
        ) async throws -> [TargetFileObject] {
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

// MARK: - CreateShardTargetFileObjects.Callable

extension Generator.CreateShardTargetFileObjects {
    typealias Callable = (
        _ buildFileSubIdentifierFile: URL,
        _ fileIdentifiersTask: Task<[BazelPath: String], Error>,
        _ createBuildFileObject: Generator.CreateBuildFileObject,
        _ readBuildFileSubIdentifiersFile:
            Generator.ReadBuildFileSubIdentifiersFile
    ) async throws -> [TargetFileObject]

    static func defaultCallable(
        buildFileSubIdentifierFile: URL,
        fileIdentifiersTask: Task<[BazelPath: String], Error>,
        createBuildFileObject: Generator.CreateBuildFileObject,
        readBuildFileSubIdentifiersFile:
            Generator.ReadBuildFileSubIdentifiersFile
    ) async throws -> [TargetFileObject] {
        let subIdentifiers = try await
            readBuildFileSubIdentifiersFile(buildFileSubIdentifierFile)

        let fileIdentifiers = try await fileIdentifiersTask.value

        return try subIdentifiers.map { subIdentifier in
            if subIdentifier.type == .product {
                return .product(
                    subIdentifier: subIdentifier,
                    identifier:
                        Identifiers.BuildFiles.id(subIdentifier: subIdentifier)
                )
            } else {
                return .buildFile(
                    createBuildFileObject(
                        subIdentifier: subIdentifier,
                        fileIdentifier: try fileIdentifiers.value(
                            for: subIdentifier.path,
                            context: "Build file referenced path"
                        )
                    )
                )
            }
        }
    }
}

enum TargetFileObject {
    case product(
        subIdentifier: Identifiers.BuildFiles.SubIdentifier,
        identifier: String
    )
    case buildFile(Object)
}
