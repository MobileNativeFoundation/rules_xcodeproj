import Foundation
import PBXProj
import XCScheme

extension Generator {
    struct ReadTransitivePreviewReferencesFile {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable =
                ReadTransitivePreviewReferencesFile.defaultCallable
        ) {
            self.callable = callable
        }

        /// Reads the file at `url`, returning a mapping of `TargetID` to
        /// `[BuildableReference]`.
        func callAsFunction(
            _ url: URL?,
            targetsByID: [TargetID: Target]
        ) async throws -> [TargetID: [BuildableReference]] {
            return try await callable(url, /*targetsByID:*/ targetsByID)
        }
    }
}

// MARK: - ReadTransitivePreviewReferencesFile.Callable

extension Generator.ReadTransitivePreviewReferencesFile {
    typealias Callable = (
        _ url: URL?,
        _ targetsByID: [TargetID: Target]
    ) async throws -> [TargetID: [BuildableReference]]

    static func defaultCallable(
        _ url: URL?,
        targetsByID: [TargetID: Target]
    ) async throws -> [TargetID: [BuildableReference]] {
        guard let url = url else {
            return [:]
        }

        var rawArgs = ArraySlice(try await url.lines.collect())

        var keysWithValues: [(TargetID, [BuildableReference])] = []
        while !rawArgs.isEmpty {
            let id =
                try rawArgs.consumeArg("target-id", as: TargetID.self, in: url)
            let buildableReferences = try rawArgs.consumeArgs(
                "buildable-references",
                as: BuildableReference.self,
                in: url,
                transform: { id in
                     try targetsByID
                        .value(
                            for: TargetID(id),
                            context: "Additional target"
                        )
                        .buildableReference
                }
            )
            keysWithValues.append((id, buildableReferences))
        }

        return Dictionary(uniqueKeysWithValues: keysWithValues)
    }
}
