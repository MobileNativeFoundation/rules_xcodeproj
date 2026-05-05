import Foundation
import PBXProj
import XCScheme

extension Generator {
    struct CreateAutomaticSchemeInfos {
        private let createTargetAutomaticSchemeInfos:
            CreateTargetAutomaticSchemeInfos

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createTargetAutomaticSchemeInfos:
                CreateTargetAutomaticSchemeInfos,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createTargetAutomaticSchemeInfos =
                createTargetAutomaticSchemeInfos

            self.callable = callable
        }

        /// Creates `SchemeInfo`s for automatically generated schemes.
        func callAsFunction(
            autogenerationMode: AutogenerationMode,
            buildPostActions: [AutogenerationConfig.Action],
            buildPreActions: [AutogenerationConfig.Action],
            buildRunPostActionsOnFailure: Bool,
            profilePostActions: [AutogenerationConfig.Action],
            profilePreActions: [AutogenerationConfig.Action],
            commandLineArguments: [TargetID: [CommandLineArgument]],
            customSchemeNames: Set<String>,
            environmentVariables: [TargetID: [EnvironmentVariable]],
            extensionHostIDs: [TargetID: [TargetID]],
            runPostActions: [AutogenerationConfig.Action],
            runPreActions: [AutogenerationConfig.Action],
            targets: [Target],
            targetsByID: [TargetID: Target],
            targetsByKey: [Target.Key: Target],
            testPostActions: [AutogenerationConfig.Action],
            testPreActions: [AutogenerationConfig.Action],
            testOptions: SchemeInfo.Test.Options?
        ) throws -> [SchemeInfo] {
            return try callable(
                /*autogenerationMode:*/ autogenerationMode,
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
                /*targets:*/ targets,
                /*targetsByID:*/ targetsByID,
                /*targetsByKey:*/ targetsByKey,
                /*testPostActions:*/ testPostActions,
                /*testPreActions:*/ testPreActions,
                /*createTargetAutomaticSchemeInfos:*/
                    createTargetAutomaticSchemeInfos,
                /*testOptions:*/ testOptions
            )
        }
    }
}

// MARK: - CreateAutomaticSchemeInfos.Callable

extension Generator.CreateAutomaticSchemeInfos {
    typealias Callable = (
        _ autogenerationMode: AutogenerationMode,
        _ buildPostActions: [AutogenerationConfig.Action],
        _ buildPreActions: [AutogenerationConfig.Action],
        _ buildRunPostActionsOnFailure: Bool,
        _ profilePostActions: [AutogenerationConfig.Action],
        _ profilePreActions: [AutogenerationConfig.Action],
        _ commandLineArguments: [TargetID: [CommandLineArgument]],
        _ customSchemeNames: Set<String>,
        _ environmentVariables: [TargetID: [EnvironmentVariable]],
        _ extensionHostIDs: [TargetID: [TargetID]],
        _ runPostActions: [AutogenerationConfig.Action],
        _ runPreActions: [AutogenerationConfig.Action],
        _ targets: [Target],
        _ targetsByID: [TargetID: Target],
        _ targetsByKey: [Target.Key: Target],
        _ testPostActions: [AutogenerationConfig.Action],
        _ testPreActions: [AutogenerationConfig.Action],
        _ createTargetAutomaticSchemeInfos:
            Generator.CreateTargetAutomaticSchemeInfos,
        _ testOptions: SchemeInfo.Test.Options?
    ) throws -> [SchemeInfo]

    static func defaultCallable(
        autogenerationMode: AutogenerationMode,
        buildPostActions: [AutogenerationConfig.Action],
        buildPreActions: [AutogenerationConfig.Action],
        buildRunPostActionsOnFailure: Bool,
        profilePostActions: [AutogenerationConfig.Action],
        profilePreActions: [AutogenerationConfig.Action],
        commandLineArguments: [TargetID: [CommandLineArgument]],
        customSchemeNames: Set<String>,
        environmentVariables: [TargetID: [EnvironmentVariable]],
        extensionHostIDs: [TargetID: [TargetID]],
        runPostActions: [AutogenerationConfig.Action],
        runPreActions: [AutogenerationConfig.Action],
        targets: [Target],
        targetsByID: [TargetID: Target],
        targetsByKey: [Target.Key: Target],
        testPostActions: [AutogenerationConfig.Action],
        testPreActions: [AutogenerationConfig.Action],
        createTargetAutomaticSchemeInfos:
            Generator.CreateTargetAutomaticSchemeInfos,
        testOptions: SchemeInfo.Test.Options?
    ) throws -> [SchemeInfo] {
        let autogenerateSchemes: Bool
        switch autogenerationMode {
        case .all:
            autogenerateSchemes = true
        case .auto:
            autogenerateSchemes = customSchemeNames.isEmpty
        case .none:
            autogenerateSchemes = false
        }

        guard autogenerateSchemes else {
            return []
        }

        return try targets
            .filter { $0.productType.shouldCreateScheme }
            // Sort targets so resulting `SchemeInfo` is properly sorted for
            // `xcschememanagement.plist`
            .sorted { lhs, rhs in
                let lhsSortOrder = lhs.productType.sortOrder
                let rhsSortOrder = rhs.productType.sortOrder
                guard lhsSortOrder == rhsSortOrder else {
                    return lhsSortOrder < rhsSortOrder
                }

                return lhs.buildableReference.blueprintName
                    .localizedStandardCompare(
                        rhs.buildableReference.blueprintName
                    ) == .orderedAscending
            }
            .flatMap { target -> [SchemeInfo] in
                let id = target.key.sortedIds.first!

                return try createTargetAutomaticSchemeInfos(
                    buildPostActions: buildPostActions,
                    buildPreActions: buildPreActions,
                    buildRunPostActionsOnFailure:
                        buildRunPostActionsOnFailure,
                    profilePostActions: profilePostActions,
                    profilePreActions: profilePreActions,
                    commandLineArguments: commandLineArguments[id, default: []],
                    customSchemeNames: customSchemeNames,
                    environmentVariables: environmentVariables[id, default: []],
                    extensionHostIDs: extensionHostIDs,
                    runPostActions: runPostActions,
                    runPreActions: runPreActions,
                    target: target,
                    targetsByID: targetsByID,
                    targetsByKey: targetsByKey,
                    testPostActions: testPostActions,
                    testPreActions: testPreActions,
                    testOptions: testOptions
                )
            }
    }
}

private extension PBXProductType {
    var shouldCreateScheme: Bool {
        switch self {
        case .messagesApplication, .watch2AppContainer, .watch2Extension:
            return false
        default:
            return true
        }
    }

    var sortOrder: Int {
        switch self {
        // Applications
        case .application,
             .commandLineTool,
             .messagesApplication,
             .onDemandInstallCapableApplication,
             .watch2App,
             .watch2AppContainer,
             .xpcService:
            return 0
        // App extensions
        case .appExtension,
             .driverExtension,
             .extensionKitExtension,
             .intentsServiceExtension,
             .messagesExtension,
             .stickerPack,
             .systemExtension,
             .tvExtension,
             .watch2Extension,
             .xcodeExtension:
            return 1
        // Tests
        case .ocUnitTestBundle,
             .uiTestBundle,
             .unitTestBundle:
            return 2
        // Others
        case .resourceBundle,
             .bundle,
             .framework,
             .staticFramework,
             .xcFramework,
             .dynamicLibrary,
             .staticLibrary,
             .instrumentsPackage,
             .metalLibrary:
            return 3
        }
    }
}
