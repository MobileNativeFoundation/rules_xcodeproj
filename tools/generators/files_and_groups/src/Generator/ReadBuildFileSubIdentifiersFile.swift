import Foundation
import PBXProj

extension Generator {
    struct ReadBuildFileSubIdentifiersFile {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Reads `[Identifiers.BuildFile.SubIdentifier]` from disk.
        func callAsFunction(
            _ url: URL
        ) async throws -> [Identifiers.BuildFiles.SubIdentifier] {
            try await callable(/*url*/ url)
        }
    }
}

// MARK: - ReadBuildFileSubIdentifiersFile.Callable

extension Generator.ReadBuildFileSubIdentifiersFile {
    typealias Callable = (
        _ url: URL
    ) async throws -> [Identifiers.BuildFiles.SubIdentifier]

    static func defaultCallable(
        _ url: URL
    ) async throws -> [Identifiers.BuildFiles.SubIdentifier] {
        return try await Identifiers.BuildFiles.SubIdentifier.decode(from: url)
    }
}
