import Foundation
import PBXProj

extension Generator {
    struct ReadFilePathsFile {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Reads file `[BazelPath]` from disk.
        func callAsFunction(
            _ url: URL
        ) async throws -> [BazelPath] {
            try await callable(/*url*/ url)
        }
    }
}

// MARK: - ReadFilePathsFile.Callable

extension Generator.ReadFilePathsFile {
    typealias Callable = (
        _ url: URL
    ) async throws -> [BazelPath]

    static func defaultCallable(
        _ url: URL
    ) async throws -> [BazelPath] {
        // The file can have at most 1 duplicate for each entry because of
        // preprocessed resource files being represented as file paths, while
        // they can also be an input to another action (e.g. codegen). Because
        // of this we use a `Set` to deduplicate the paths.
        return Set(try await url.lines.collect()).map { BazelPath($0) }
    }
}
