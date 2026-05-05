import PBXProj
import XCScheme

extension Generator {
    struct CreateAutomaticSchemeInfo {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.callable = callable
        }

        /// Creates a `SchemeInfo` for an automatically generated scheme.
        func callAsFunction(
            buildPostActions: [AutogenerationConfig.Action],
            buildPreActions: [AutogenerationConfig.Action],
            buildRunPostActionsOnFailure: Bool,
            profilePostActions: [AutogenerationConfig.Action],
            profilePreActions: [AutogenerationConfig.Action],
            commandLineArguments: [CommandLineArgument],
            customSchemeNames: Set<String>,
            environmentVariables: [EnvironmentVariable],
            extensionHost: Target?,
            runPostActions: [AutogenerationConfig.Action],
            runPreActions: [AutogenerationConfig.Action],
            target: Target,
            testPostActions: [AutogenerationConfig.Action],
            testPreActions: [AutogenerationConfig.Action],
            testOptions: SchemeInfo.Test.Options?
        ) throws -> SchemeInfo? {
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
                /*extensionHost:*/ extensionHost,
                /*runPostActions:*/ runPostActions,
                /*runPreActions:*/ runPreActions,
                /*target:*/ target,
                /*testPostActions:*/ testPostActions,
                /*testPreActions:*/ testPreActions,
                /*testOptions:*/ testOptions
            )
        }
    }
}

// MARK: - CreateAutomaticSchemeInfo.Callable

extension Generator.CreateAutomaticSchemeInfo {
    typealias Callable = (
        _ buildPostActions: [AutogenerationConfig.Action],
        _ buildPreActions: [AutogenerationConfig.Action],
        _ buildRunPostActionsOnFailure: Bool,
        _ profilePostActions: [AutogenerationConfig.Action],
        _ profilePreActions: [AutogenerationConfig.Action],
        _ commandLineArguments: [CommandLineArgument],
        _ customSchemeNames: Set<String>,
        _ environmentVariables: [EnvironmentVariable],
        _ extensionHost: Target?,
        _ runPostActions: [AutogenerationConfig.Action],
        _ runPreActions: [AutogenerationConfig.Action],
        _ target: Target,
        _ testPostActions: [AutogenerationConfig.Action],
        _ testPreActions: [AutogenerationConfig.Action],
        _ testOptions: SchemeInfo.Test.Options?
    ) throws -> SchemeInfo?

    static func defaultCallable(
        buildPostActions: [AutogenerationConfig.Action],
        buildPreActions: [AutogenerationConfig.Action],
        buildRunPostActionsOnFailure: Bool,
        profilePostActions: [AutogenerationConfig.Action],
        profilePreActions: [AutogenerationConfig.Action],
        commandLineArguments: [CommandLineArgument],
        customSchemeNames: Set<String>,
        environmentVariables: [EnvironmentVariable],
        extensionHost: Target?,
        runPostActions: [AutogenerationConfig.Action],
        runPreActions: [AutogenerationConfig.Action],
        target: Target,
        testPostActions: [AutogenerationConfig.Action],
        testPreActions: [AutogenerationConfig.Action],
        testOptions: SchemeInfo.Test.Options?
    ) throws -> SchemeInfo? {
        let baseSchemeName = target.buildableReference.blueprintName.schemeName

        guard !customSchemeNames.contains(baseSchemeName) else {
            return nil
        }

        let productType = target.productType
        let isTest = productType.isTest

        let name: String
        let launchTarget: SchemeInfo.LaunchTarget?
        let buildTargets: [Target]
        if let extensionHost {
            name = """
\(baseSchemeName) in \
\(extensionHost.buildableReference.blueprintName.schemeName)
"""

            launchTarget =
                .target(primary: target, extensionHost: extensionHost)
            buildTargets = []
        } else {
            name = baseSchemeName

            if productType.isLaunchable {
                launchTarget = .target(primary: target, extensionHost: nil)
                buildTargets = []
            } else {
                launchTarget = nil
                buildTargets = [target]
            }
        }

        let testCommandLineArguments: [CommandLineArgument]
        let testEnvironmentVariables: [EnvironmentVariable]
        let testUseRunArgsAndEnv: Bool
        let runCommandLineArguments: [CommandLineArgument]
        let runEnvironmentVariables: [EnvironmentVariable]
        if isTest {
            testUseRunArgsAndEnv = false
            testCommandLineArguments = commandLineArguments
            testEnvironmentVariables =
                .defaultEnvironmentVariables + environmentVariables

            runCommandLineArguments = []
            runEnvironmentVariables = []
        } else {
            testUseRunArgsAndEnv = true
            testCommandLineArguments = []
            testEnvironmentVariables = []

            runCommandLineArguments = commandLineArguments
            runEnvironmentVariables =
                .defaultEnvironmentVariables + environmentVariables
        }

        let buildExecutionActions = buildPreActions.map {
            SchemeInfo.ExecutionAction(
                title: $0.title,
                scriptText: $0.scriptText,
                action: .build,
                isPreAction: true,
                target: target,
                order: $0.order
            )
        } + buildPostActions.map {
            SchemeInfo.ExecutionAction(
                title: $0.title,
                scriptText: $0.scriptText,
                action: .build,
                isPreAction: false,
                target: target,
                order: $0.order
            )
        }
        let runExecutionActions = runPreActions.map {
            SchemeInfo.ExecutionAction(
                title: $0.title,
                scriptText: $0.scriptText,
                action: .run,
                isPreAction: true,
                target: target,
                order: $0.order
            )
        } + runPostActions.map {
            SchemeInfo.ExecutionAction(
                title: $0.title,
                scriptText: $0.scriptText,
                action: .run,
                isPreAction: false,
                target: target,
                order: $0.order
            )
        }
        let testExecutionActions = testPreActions.map {
            SchemeInfo.ExecutionAction(
                title: $0.title,
                scriptText: $0.scriptText,
                action: .test,
                isPreAction: true,
                target: target,
                order: $0.order
            )
        } + testPostActions.map {
            SchemeInfo.ExecutionAction(
                title: $0.title,
                scriptText: $0.scriptText,
                action: .test,
                isPreAction: false,
                target: target,
                order: $0.order
            )
        }
        let profileExecutionActions = profilePreActions.map {
            SchemeInfo.ExecutionAction(
                title: $0.title,
                scriptText: $0.scriptText,
                action: .profile,
                isPreAction: true,
                target: target,
                order: $0.order
            )
        } + profilePostActions.map {
            SchemeInfo.ExecutionAction(
                title: $0.title,
                scriptText: $0.scriptText,
                action: .profile,
                isPreAction: false,
                target: target,
                order: $0.order
            )
        }

        return SchemeInfo(
            name: name,
            test: .init(
                buildTargets: [],
                commandLineArguments: testCommandLineArguments,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: testEnvironmentVariables,
                options: testOptions,
                testTargets: isTest ?
                    [.init(target: target, isEnabled: true)] : [],
                useRunArgsAndEnv: testUseRunArgsAndEnv,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildTargets: buildTargets,
                commandLineArguments: runCommandLineArguments,
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                enableMainThreadChecker: false,
                enableThreadPerformanceChecker: false,
                environmentVariables: runEnvironmentVariables,
                launchTarget: launchTarget,
                runBuildPostActionsOnFailure:
                    buildRunPostActionsOnFailure,
                storeKitConfiguration: nil,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: launchTarget,
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            executionActions:
                buildExecutionActions +
                runExecutionActions +
                testExecutionActions +
                profileExecutionActions
        )
    }
}

private extension String {
    var schemeName: String {
        return replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}

private extension PBXProductType {
    var isLaunchable: Bool {
        switch self {
        case .application,
             .messagesApplication,
             .onDemandInstallCapableApplication,
             .watch2App,
             .watch2AppContainer,
             .appExtension,
             .intentsServiceExtension,
             .messagesExtension,
             .tvExtension,
             .extensionKitExtension,
             .xcodeExtension,
             .driverExtension,
             .systemExtension,
             .commandLineTool,
             .xpcService:
            return true
        case .stickerPack,
             .watch2Extension,
             .resourceBundle,
             .bundle,
             .ocUnitTestBundle,
             .unitTestBundle,
             .uiTestBundle,
             .framework,
             .staticFramework,
             .xcFramework,
             .dynamicLibrary,
             .staticLibrary,
             .instrumentsPackage,
             .metalLibrary:
            return false
        }
    }

    var isTest: Bool {
        switch self {
        case .unitTestBundle, .uiTestBundle: return true
        default: return false
        }
    }
}
