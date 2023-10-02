import Foundation
import PBXProj

extension Generator {
    struct ReadFolderPathsFile {
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

// MARK: - ReadFolderPathsFile.Callable

extension Generator.ReadFolderPathsFile {
    typealias Callable = (
        _ url: URL
    ) async throws -> [BazelPath]

    static func defaultCallable(
        _ url: URL
    ) async throws -> [BazelPath] {
        return try await url.lines.collect()
            .map { BazelPath($0, isFolder: true) }
    }
}
