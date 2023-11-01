import Foundation
import PBXProj

extension Generator {
    struct ReadKeyedSwiftDebugSettings {
        private let readTargetSwiftDebugSettingsFile:
            ReadTargetSwiftDebugSettingsFile

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            readTargetSwiftDebugSettingsFile: ReadTargetSwiftDebugSettingsFile,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.readTargetSwiftDebugSettingsFile =
                readTargetSwiftDebugSettingsFile

            self.callable = callable
        }

        /// Reads the keyed Swift debug settings from disk.
        func callAsFunction(
            keysAndFiles: [(key: String, url: URL)]
        ) async throws -> [(key: String, settings: TargetSwiftDebugSettings)] {
            try await callable(
                /*keysAndFiles:*/ keysAndFiles,
                /*readTargetSwiftDebugSettingsFile:*/
                    readTargetSwiftDebugSettingsFile
            )
        }
    }
}

// MARK: - ReadKeyedSwiftDebugSettings.Callable

extension Generator.ReadKeyedSwiftDebugSettings {
    typealias Callable = (
        _ keysAndFiles: [(key: String, url: URL)],
        _ readTargetSwiftDebugSettingsFile: ReadTargetSwiftDebugSettingsFile
    ) async throws -> [(key: String, settings: TargetSwiftDebugSettings)]

    static func defaultCallable(
        keysAndFiles: [(key: String, url: URL)],
        readTargetSwiftDebugSettingsFile: ReadTargetSwiftDebugSettingsFile
    ) async throws -> [(key: String, settings: TargetSwiftDebugSettings)] {
        return try await withThrowingTaskGroup(
            of: (key: String, settings: TargetSwiftDebugSettings).self
        ) { group in
            for (key, url) in keysAndFiles {
                group.addTask {
                    return (
                        key,
                        try await readTargetSwiftDebugSettingsFile(from: url)
                    )
                }
            }

            var keyedSwiftDebugSettings:
                [(key: String, settings: TargetSwiftDebugSettings)] = []
            for try await result in group {
                keyedSwiftDebugSettings.append(result)
            }

            return keyedSwiftDebugSettings.sorted(by: { $0.key < $1.key })
        }
    }
}
