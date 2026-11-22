import Foundation
import PBXProj

extension Generator {
    struct ReadBuildableFoldersFile {
        private let callable: Callable

        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        func callAsFunction(_ url: URL) async throws -> [BazelPath] {
            try await callable(url)
        }
    }
}

extension Generator.ReadBuildableFoldersFile {
    typealias Callable = (_ url: URL) async throws -> [BazelPath]

    static func defaultCallable(_ url: URL) async throws -> [BazelPath] {
        return try await Set(url.lines.collect()).map { BazelPath($0) }
    }
}
