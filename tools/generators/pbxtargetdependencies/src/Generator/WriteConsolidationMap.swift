import Foundation
import GeneratorCommon
import PBXProj

extension Generator {
    struct WriteConsolidationMap {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Writes a consolidation map to disk.
        func callAsFunction(
            _ entries: [ConsolidationMapEntry],
            to url: URL
        ) throws {
            try callable(/*entries:*/ entries, /*url*/ url)
        }
    }
}

// MARK: - WriteConsolidationMap.Callable

extension Generator.WriteConsolidationMap {
    typealias Callable = (
        _ entries: [ConsolidationMapEntry],
        _ url: URL
    ) throws -> Void

    static func defaultCallable(
        _ entries: [ConsolidationMapEntry],
        to url: URL
    ) throws {
        do {
            // Create parent directory
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw PreconditionError(message: """
Failed to create parent directories for "\(url.path)": \
\(error.localizedDescription)
""")
        }

        // Write
        try ConsolidationMapEntry.encode(entries, to: url)
    }
}
