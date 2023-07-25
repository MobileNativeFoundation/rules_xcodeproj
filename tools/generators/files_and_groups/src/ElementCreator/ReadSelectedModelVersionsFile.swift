import Foundation
import GeneratorCommon
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
        /// file paths to selected `.xcdatamodel` file names.
        func callAsFunction(_ url: URL) throws -> [BazelPath: String] {
            return try callable(url)
        }
    }
}

// MARK: - ReadSelectedModelVersionsFile.Callable

extension ElementCreator.ReadSelectedModelVersionsFile {
    typealias Callable = (_ url: URL) throws -> [BazelPath: String]

    static func defaultCallable(_ url: URL) throws -> [BazelPath: String] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase


        do {
            return try decoder
                .decode([BazelPath: String].self, from: Data(contentsOf: url))
        } catch {
            throw PreconditionError(message: """
"\(url.path)": \(error.localizedDescription)
""")
        }
    }
}
