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
            commandLineArguments: [CommandLineArgument],
            customSchemeNames: Set<String>,
            environmentVariables: [EnvironmentVariable],
            extensionHost: Target?,
            target: Target,
            transitivePreviewReferences: [BuildableReference]
        ) throws -> SchemeInfo? {
            return try callable(
                /*commandLineArguments:*/ commandLineArguments,
                /*customSchemeNames:*/ customSchemeNames,
                /*environmentVariables:*/ environmentVariables,
                /*extensionHost:*/ extensionHost,
                /*target:*/ target,
                /*transitivePreviewReferences:*/ transitivePreviewReferences
            )
        }
    }
}

// MARK: - CreateAutomaticSchemeInfo.Callable

extension Generator.CreateAutomaticSchemeInfo {
    typealias Callable = (
        _ commandLineArguments: [CommandLineArgument],
        _ customSchemeNames: Set<String>,
        _ environmentVariables: [EnvironmentVariable],
        _ extensionHost: Target?,
        _ target: Target,
        _ transitivePreviewReferences: [BuildableReference]
    ) throws -> SchemeInfo?

    static func defaultCallable(
        commandLineArguments: [CommandLineArgument],
        customSchemeNames: Set<String>,
        environmentVariables: [EnvironmentVariable],
        extensionHost: Target?,
        target: Target,
        transitivePreviewReferences: [BuildableReference]
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
                .init(primary: target, extensionHost: extensionHost)
            buildTargets = []
        } else {
            name = baseSchemeName

            if productType.isLaunchable {
                launchTarget = .init(primary: target, extensionHost: nil)
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

        return SchemeInfo(
            name: name,
            test: .init(
                buildTargets: [],
                commandLineArguments: testCommandLineArguments,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                environmentVariables: testEnvironmentVariables,
                testTargets: isTest ?
                    [.init(target: target, enabled: true)] : [],
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
                environmentVariables: runEnvironmentVariables,
                launchTarget: launchTarget,
                transitivePreviewReferences: transitivePreviewReferences,
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
            executionActions: []
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
        default:
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
