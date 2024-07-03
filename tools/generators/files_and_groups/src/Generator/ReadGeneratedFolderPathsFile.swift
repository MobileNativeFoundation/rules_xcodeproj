import Foundation
import PBXProj
import ToolCommon

extension Generator {
    struct ReadGeneratedFolderPathsFile {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Reads file `[GeneratedPath]` from disk.
        func callAsFunction(
            _ url: URL
        ) async throws -> [GeneratedPath] {
            try await callable(/*url*/ url)
        }
    }
}

// MARK: - ReadGeneratedFolderPathsFile.Callable

extension Generator.ReadGeneratedFolderPathsFile {
    typealias Callable = (
        _ url: URL
    ) async throws -> [GeneratedPath]

    static func defaultCallable(
        _ url: URL
    ) async throws -> [GeneratedPath] {
        var iterator = url.allLines.makeAsyncIterator()

        var generatedPaths: [GeneratedPath] = []
        while true {
            guard let path = try await iterator.next() else{
                break
            }

            guard let package = try await iterator.next() else {
                throw PreconditionError(
                    message: url.prefixMessage("Missing `package`")
                )
            }

            guard let config = try await iterator.next() else {
                throw PreconditionError(
                    message: url.prefixMessage("Missing `config`")
                )
            }

            generatedPaths.append(GeneratedPath(
                config: config,
                package: BazelPath(package),
                path: BazelPath(path, isFolder: true)
            ))
        }

        return generatedPaths
    }
}
