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

        /// Returns an `AsyncSequence` that reads folder `BazelPath` from disk.
        func callAsFunction(
            _ url: URL
        ) -> AsyncMapSequence<AsyncLineSequence<URL.AsyncBytes>, BazelPath> {
            return callable(/*url*/ url)
        }
    }
}

// MARK: - ReadFolderPathsFile.Callable

extension Generator.ReadFolderPathsFile {
    typealias Callable = (
        _ url: URL
    ) -> AsyncMapSequence<AsyncLineSequence<URL.AsyncBytes>, BazelPath>

    static func defaultCallable(
        _ url: URL
    ) -> AsyncMapSequence<AsyncLineSequence<URL.AsyncBytes>, BazelPath> {
        return url.lines
            .map { BazelPath($0, isFolder: true) }
    }
}
