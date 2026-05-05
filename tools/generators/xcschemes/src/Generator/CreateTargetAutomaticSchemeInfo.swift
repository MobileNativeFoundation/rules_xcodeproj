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
            buildPostActions: [AutogenerationConfig.Action],
            buildPreActions: [AutogenerationConfig.Action],
            buildRunPostActionsOnFailure: Bool,
            profilePostActions: [AutogenerationConfig.Action],
            profilePreActions: [AutogenerationConfig.Action],
            commandLineArguments: [CommandLineArgument],
            customSchemeNames: Set<String>,
            environmentVariables: [EnvironmentVariable],
            extensionHostIDs: [TargetID: [TargetID]],
            runPostActions: [AutogenerationConfig.Action],
            runPreActions: [AutogenerationConfig.Action],
            target: Target,
            targetsByID: [TargetID: Target],
            targetsByKey: [Target.Key: Target],
            testPostActions: [AutogenerationConfig.Action],
            testPreActions: [AutogenerationConfig.Action],
            testOptions: SchemeInfo.Test.Options?
        ) throws -> [SchemeInfo] {
            return try callable(
                /*buildPostActions:*/ buildPostActions,
                /*buildPreActions:*/ buildPreActions,
                /*buildRunPostActionsOnFailure:*/
                    buildRunPostActionsOnFailure,
                /*profilePostActions:*/ profilePostActions,
                /*profilePreActions:*/ profilePreActions,
                /*commandLineArguments:*/ commandLineArguments,
                /*customSchemeNames:*/ customSchemeNames,
                /*environmentVariables:*/ environmentVariables,
                /*extensionHostIDs:*/ extensionHostIDs,
                /*runPostActions:*/ runPostActions,
                /*runPreActions:*/ runPreActions,
                /*target:*/ target,
                /*targetsByID:*/ targetsByID,
                /*targetsByKey:*/ targetsByKey,
                /*testPostActions:*/ testPostActions,
                /*testPreActions:*/ testPreActions,
                /*testOptions:*/ testOptions,
                /*createAutomaticSchemeInfo:*/ createAutomaticSchemeInfo
            )
        }
    }
}

// MARK: - CreateTargetAutomaticSchemeInfos.Callable

extension Generator.CreateTargetAutomaticSchemeInfos {
    typealias Callable = (
        _ buildPostActions: [AutogenerationConfig.Action],
        _ buildPreActions: [AutogenerationConfig.Action],
        _ buildRunPostActionsOnFailure: Bool,
        _ profilePostActions: [AutogenerationConfig.Action],
        _ profilePreActions: [AutogenerationConfig.Action],
        _ commandLineArguments: [CommandLineArgument],
        _ customSchemeNames: Set<String>,
        _ environmentVariables: [EnvironmentVariable],
        _ extensionHostIDs: [TargetID: [TargetID]],
        _ runPostActions: [AutogenerationConfig.Action],
        _ runPreActions: [AutogenerationConfig.Action],
        _ target: Target,
        _ targetsByID: [TargetID: Target],
        _ targetsByKey: [Target.Key: Target],
        _ testPostActions: [AutogenerationConfig.Action],
        _ testPreActions: [AutogenerationConfig.Action],
        _ testOptions: SchemeInfo.Test.Options?,
        _ createAutomaticSchemeInfo: Generator.CreateAutomaticSchemeInfo
    ) throws -> [SchemeInfo]

    static func defaultCallable(
        buildPostActions: [AutogenerationConfig.Action],
        buildPreActions: [AutogenerationConfig.Action],
        buildRunPostActionsOnFailure: Bool,
        profilePostActions: [AutogenerationConfig.Action],
        profilePreActions: [AutogenerationConfig.Action],
        commandLineArguments: [CommandLineArgument],
        customSchemeNames: Set<String>,
        environmentVariables: [EnvironmentVariable],
        extensionHostIDs: [TargetID: [TargetID]],
        runPostActions: [AutogenerationConfig.Action],
        runPreActions: [AutogenerationConfig.Action],
        target: Target,
        targetsByID: [TargetID: Target],
        targetsByKey: [Target.Key: Target],
        testPostActions: [AutogenerationConfig.Action],
        testPreActions: [AutogenerationConfig.Action],
        testOptions: SchemeInfo.Test.Options?,
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

        if extensionHostKeys.isEmpty {
            guard let schemeInfo = try createAutomaticSchemeInfo(
                buildPostActions: buildPostActions,
                buildPreActions: buildPreActions,
                buildRunPostActionsOnFailure:
                    buildRunPostActionsOnFailure,
                profilePostActions: profilePostActions,
                profilePreActions: profilePreActions,
                commandLineArguments: commandLineArguments,
                customSchemeNames: customSchemeNames,
                environmentVariables: environmentVariables,
                extensionHost: nil,
                runPostActions: runPostActions,
                runPreActions: runPreActions,
                target: target,
                testPostActions: testPostActions,
                testPreActions: testPreActions,
                testOptions: testOptions
            ) else {
                return []
            }
            return [schemeInfo]
        } else {
            return try extensionHostKeys.compactMap { key in
                return try createAutomaticSchemeInfo(
                    buildPostActions: buildPostActions,
                    buildPreActions: buildPreActions,
                    buildRunPostActionsOnFailure:
                        buildRunPostActionsOnFailure,
                    profilePostActions: profilePostActions,
                    profilePreActions: profilePreActions,
                    commandLineArguments: commandLineArguments,
                    customSchemeNames: customSchemeNames,
                    environmentVariables: environmentVariables,
                    extensionHost: targetsByKey[key]!,
                    runPostActions: runPostActions,
                    runPreActions: runPreActions,
                    target: target,
                    testPostActions: testPostActions,
                    testPreActions: testPreActions,
                    testOptions: testOptions
                )
            }
        }
    }
}
