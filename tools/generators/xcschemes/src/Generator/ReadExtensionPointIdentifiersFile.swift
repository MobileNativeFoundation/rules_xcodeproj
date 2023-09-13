import Foundation
import GeneratorCommon
import PBXProj

extension Generator {
    class ReadExtensionPointIdentifiersFile {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable =
                ReadExtensionPointIdentifiersFile.defaultCallable
        ) {
            self.callable = callable
        }

        /// Reads the file at `url`, returning a mapping of `TargetID` to
        // `ExtensionPointIdentifier`.
        func callAsFunction(
            _ url: URL
        ) throws -> [TargetID: ExtensionPointIdentifier] {
            return try callable(url)
        }
    }
}

// MARK: - ReadExtensionPointIdentifiersFile.Callable

extension Generator.ReadExtensionPointIdentifiersFile {
    typealias Callable = (
        _ url: URL
    ) throws -> [TargetID: ExtensionPointIdentifier]

    static func defaultCallable(
        _ url: URL
    ) throws -> [TargetID: ExtensionPointIdentifier] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(
                [TargetID: ExtensionPointIdentifier].self,
                from: Data(contentsOf: url)
            )
        } catch {
            throw PreconditionError(message: """
"\(url.path)": \(error.localizedDescription)
""")
        }
    }
}
