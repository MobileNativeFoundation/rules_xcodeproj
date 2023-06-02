import Foundation
import PBXProj

extension ElementCreator {
    class ReadSelectedModelVersionsFile {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable =
                ReadSelectedModelVersionsFile.defaultCallable
        ) {
            self.callable = callable
        }

        /// Reads the file at `url`, returning a mapping of `.xcdatamodeld`
        /// file paths to selected `.xcdatamodel` file files.
        func callAsFunction(_ url: URL) throws -> [BazelPath: BazelPath] {
            return try callable(url)
        }
    }
}

// MARK: - ReadSelectedModelVersionsFile.Callable

extension ElementCreator.ReadSelectedModelVersionsFile {
    typealias Callable = (_ url: URL) throws -> [BazelPath: BazelPath]

    static func defaultCallable(_ url: URL) throws -> [BazelPath: BazelPath] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder
            .decode([BazelPath: BazelPath].self, from: Data(contentsOf: url))
    }
}
