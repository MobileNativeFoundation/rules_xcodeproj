import Foundation
import PBXProj
import XCScheme

extension Generator {
    struct CreateTargetAutomaticSchemeInfos {
        private let createAutomaticSchemeInfo: CreateAutomaticSchemeInfo

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createAutomaticSchemeInfo: CreateAutomaticSchemeInfo,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createAutomaticSchemeInfo = createAutomaticSchemeInfo

            self.callable = callable
        }

        /// Creates `SchemeInfo`s for a target's automatically generated
        /// schemes.
        func callAsFunction(
            extensionHostIDs: [TargetID: [TargetID]],
            target: Target,
            targetsByID: [TargetID: Target],
            targetsByKey: [Target.Key: Target],
            transitivePreviewReferences: [TargetID: [BuildableReference]]
        ) throws -> [SchemeInfo] {
            return try callable(
                /*extensionHostIDs:*/ extensionHostIDs,
                /*target:*/ target,
                /*targetsByID:*/ targetsByID,
                /*targetsByKey:*/ targetsByKey,
                /*transitivePreviewReferences:*/ transitivePreviewReferences,
                /*createAutomaticSchemeInfo:*/ createAutomaticSchemeInfo
            )
        }
    }
}

// MARK: - CreateTargetAutomaticSchemeInfos.Callable

extension Generator.CreateTargetAutomaticSchemeInfos {
    typealias Callable = (
        _ extensionHostIDs: [TargetID: [TargetID]],
        _ target: Target,
        _ targetsByID: [TargetID: Target],
        _ targetsByKey: [Target.Key: Target],
        _ transitivePreviewReferences: [TargetID: [BuildableReference]],
        _ createAutomaticSchemeInfo: Generator.CreateAutomaticSchemeInfo
    ) throws -> [SchemeInfo]

    static func defaultCallable(
        extensionHostIDs: [TargetID: [TargetID]],
        target: Target,
        targetsByID: [TargetID: Target],
        targetsByKey: [Target.Key: Target],
        transitivePreviewReferences: [TargetID: [BuildableReference]],
        createAutomaticSchemeInfo: Generator.CreateAutomaticSchemeInfo
    ) throws -> [SchemeInfo] {
        let extensionHostKeys: Set<Target.Key>
        if extensionHostIDs.isEmpty {
            extensionHostKeys = []
        } else {
            extensionHostKeys = Set(
                try target.key.sortedIds
                    .flatMap { id in
                        return try extensionHostIDs[id, default: []]
                            .map { id in
                                return try targetsByID.value(
                                    for: id,
                                    context: "Extension host target ID"
                                ).key
                            }
                    }
            )
        }

        let transitivePreviewReferences = transitivePreviewReferences[
            target.key.sortedIds.first!,
            default: []
        ]

        if extensionHostKeys.isEmpty {
            return [
                try createAutomaticSchemeInfo(
                    extensionHost: nil,
                    target: target,
                    transitivePreviewReferences: transitivePreviewReferences
                )
            ]
        } else {
            return try extensionHostKeys.map { key in
                return try createAutomaticSchemeInfo(
                    extensionHost: targetsByKey[key]!,
                    target: target,
                    transitivePreviewReferences: transitivePreviewReferences
                )
            }
        }
    }
}
