import Foundation
import PBXProj

extension Generator {
    struct WriteConsolidationMaps {
        private let writeConsolidationMap: WriteConsolidationMap

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            writeConsolidationMap: WriteConsolidationMap,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.writeConsolidationMap = writeConsolidationMap

            self.callable = callable
        }

        /// Writes a consolidation map to disk.
        func callAsFunction(
            _ consolidationMaps: [URL : [ConsolidationMapEntry]]
        ) async throws {
            try await callable(
                /*consolidationMaps:*/ consolidationMaps,
                /*writeConsolidationMap:*/ writeConsolidationMap
            )
        }
    }
}

// MARK: - WriteConsolidationMaps.Callable

extension Generator.WriteConsolidationMaps {
    typealias Callable = (
        _ consolidationMaps: [URL : [ConsolidationMapEntry]],
        _ writeConsolidationMap: Generator.WriteConsolidationMap
    ) async throws -> Void

    static func defaultCallable(
        _ consolidationMaps: [URL : [ConsolidationMapEntry]],
        writeConsolidationMap: Generator.WriteConsolidationMap
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (outputPath, entries) in consolidationMaps {
                group.addTask {
                    try writeConsolidationMap(entries, to: outputPath)
                }
            }

            try await group.waitForAll()
        }
    }
}
