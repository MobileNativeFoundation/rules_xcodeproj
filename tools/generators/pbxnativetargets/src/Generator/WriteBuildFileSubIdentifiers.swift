import Foundation
import PBXProj
import ToolCommon

extension Generator {
    struct WriteBuildFileSubIdentifiers {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Writes `[Identifiers.BuildFiles.SubIdentifier]` to disk.
        func callAsFunction(
            _ subIdentifiers: [Identifiers.BuildFiles.SubIdentifier],
            to url: URL
        ) throws {
            try callable(/*subIdentifiers:*/ subIdentifiers, /*url*/ url)
        }
    }
}

// MARK: - WriteBuildFileSubIdentifiers.Callable

extension Generator.WriteBuildFileSubIdentifiers {
    typealias Callable = (
        _ subIdentifiers: [Identifiers.BuildFiles.SubIdentifier],
        _ url: URL
    ) throws -> Void

    static func defaultCallable(
        _ subIdentifiers: [Identifiers.BuildFiles.SubIdentifier],
        to url: URL
    ) throws {
        do {
            // Create parent directory
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw PreconditionError(message: url.prefixMessage("""
Failed to create parent directories: \(error.localizedDescription)
"""))
        }

        // Write
        try Identifiers.BuildFiles.SubIdentifier.encode(subIdentifiers, to: url)
    }
}
