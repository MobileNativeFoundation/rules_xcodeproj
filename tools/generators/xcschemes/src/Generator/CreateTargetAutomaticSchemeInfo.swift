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
            commandLineArguments: [CommandLineArgument],
            customSchemeNames: Set<String>,
            environmentVariables: [EnvironmentVariable],
            extensionHostIDs: [TargetID: [TargetID]],
            target: Target,
            targetsByID: [TargetID: Target],
            targetsByKey: [Target.Key: Target],
            transitivePreviewReferences: [TargetID: [BuildableReference]]
        ) throws -> [SchemeInfo] {
            return try callable(
                /*commandLineArguments:*/ commandLineArguments,
                /*customSchemeNames:*/ customSchemeNames,
                /*environmentVariables:*/ environmentVariables,
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
        _ commandLineArguments: [CommandLineArgument],
        _ customSchemeNames: Set<String>,
        _ environmentVariables: [EnvironmentVariable],
        _ extensionHostIDs: [TargetID: [TargetID]],
        _ target: Target,
        _ targetsByID: [TargetID: Target],
        _ targetsByKey: [Target.Key: Target],
        _ transitivePreviewReferences: [TargetID: [BuildableReference]],
        _ createAutomaticSchemeInfo: Generator.CreateAutomaticSchemeInfo
    ) throws -> [SchemeInfo]

    static func defaultCallable(
        commandLineArguments: [CommandLineArgument],
        customSchemeNames: Set<String>,
        environmentVariables: [EnvironmentVariable],
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

        let id = target.key.sortedIds.first!

        let transitivePreviewReferences = transitivePreviewReferences[
            id,
            default: []
        ]

        if extensionHostKeys.isEmpty {
            guard let schemeInfo = try createAutomaticSchemeInfo(
                commandLineArguments: commandLineArguments,
                customSchemeNames: customSchemeNames,
                environmentVariables: environmentVariables,
                extensionHost: nil,
                target: target,
                transitivePreviewReferences: transitivePreviewReferences
            ) else {
                return []
            }
            return [schemeInfo]
        } else {
            return try extensionHostKeys.compactMap { key in
                return try createAutomaticSchemeInfo(
                    commandLineArguments: commandLineArguments,
                    customSchemeNames: customSchemeNames,
                    environmentVariables: environmentVariables,
                    extensionHost: targetsByKey[key]!,
                    target: target,
                    transitivePreviewReferences: transitivePreviewReferences
                )
            }
        }
    }
}
