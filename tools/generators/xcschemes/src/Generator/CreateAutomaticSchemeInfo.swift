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
            extensionHost: Target?,
            target: Target,
            transitivePreviewReferences: [BuildableReference]
        ) throws -> SchemeInfo {
            return try callable(
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
        _ extensionHost: Target?,
        _ target: Target,
        _ transitivePreviewReferences: [BuildableReference]
    ) throws -> SchemeInfo

    static func defaultCallable(
        extensionHost: Target?,
        target: Target,
        transitivePreviewReferences: [BuildableReference]
    ) throws -> SchemeInfo {
        let productType = target.productType
        let isTest = productType.isTest

        let name: String
        let launchTarget: SchemeInfo.LaunchTarget?
        let buildOnlyTargets: [SchemeInfo.BuildableTarget]
        if let extensionHost {
            name = """
\(target.buildableReference.blueprintName.schemeName) in \
\(extensionHost.buildableReference.blueprintName.schemeName)
"""

            launchTarget =
                .init(primary: .init(target), extensionHost: extensionHost)
            buildOnlyTargets = []
        } else {
            name = target.buildableReference.blueprintName.schemeName

            if productType.isLaunchable {
                launchTarget = .init(primary: .init(target), extensionHost: nil)
                buildOnlyTargets = []
            } else {
                launchTarget = nil
                buildOnlyTargets = [.init(target)]
            }
        }

        return SchemeInfo(
            name: name,
            test: .init(
                buildOnlyTargets: [],
                commandLineArguments: [],
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                environmentVariables: [],
                testTargets: isTest ? [.init(target)] : [],
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            ),
            run: .init(
                buildOnlyTargets: buildOnlyTargets,
                commandLineArguments: [],
                customWorkingDirectory: nil,
                enableAddressSanitizer: false,
                enableThreadSanitizer: false,
                enableUBSanitizer: false,
                environmentVariables: .baseEnvironmentVariables,
                launchTarget: launchTarget,
                transitivePreviewReferences: transitivePreviewReferences,
                xcodeConfiguration: nil
            ),
            profile: .init(
                buildOnlyTargets: [],
                commandLineArguments: [],
                customWorkingDirectory: nil,
                environmentVariables: [],
                launchTarget: launchTarget,
                useRunArgsAndEnv: true,
                xcodeConfiguration: nil
            )
        )
    }
}

private extension String {
    var schemeName: String {
        return replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}

private extension SchemeInfo.BuildableTarget {
    init(_ target: Target) {
        self.init(
            target: target,
            preActions: [],
            postActions: []
        )
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
