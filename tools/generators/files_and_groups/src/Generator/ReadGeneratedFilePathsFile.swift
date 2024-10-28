import Foundation
import PBXProj
import ToolCommon

struct GeneratedPath: Hashable {
    let config: String
    let package: BazelPath
    let path: BazelPath
}

extension Generator {
    struct ReadGeneratedFilePathsFile {
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

// MARK: - ReadGeneratedFilePathsFile.Callable

extension Generator.ReadGeneratedFilePathsFile {
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
                path: BazelPath(path, isFolder: false)
            ))
        }


        // The file can have at most 1 duplicate for each entry because of
        // preprocessed resource files being represented as file paths, while
        // they can also be an input to another action (e.g. codegen). Because
        // of this we use a `Set` to deduplicate the paths.
        return Array(Set(generatedPaths))
    }
}
