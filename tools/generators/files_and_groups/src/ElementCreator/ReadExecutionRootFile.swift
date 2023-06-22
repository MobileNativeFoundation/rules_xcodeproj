import Foundation
import PBXProj

extension ElementCreator {
    class ReadExecutionRootFile {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable = ReadExecutionRootFile.defaultCallable
        ) {
            self.callable = callable
        }

        /// Reads the file at `url`, returning the absolute path to the Bazel
        /// execution root.
        func callAsFunction(_ url: URL) throws -> String {
            return try callable(url)
        }
    }
}

// MARK: - ReadExecutionRootFile.Callable

extension ElementCreator.ReadExecutionRootFile {
    typealias Callable = (_ url: URL) throws -> String

    static func defaultCallable(_ url: URL) throws -> String {
        return try url.readExecutionRootFile()
    }
}
