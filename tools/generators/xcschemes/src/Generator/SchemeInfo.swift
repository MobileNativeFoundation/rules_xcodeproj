import XCScheme

/// Provides information needed to create a custom scheme.
struct SchemeInfo: Equatable {
    struct BuildableTarget: Equatable {
        let target: Target
        let preActions: [ExecutionAction]
        let postActions: [ExecutionAction]
    }

    struct ExecutionAction: Equatable {
        let title: String
        let scriptText: String
        let forBuild: Bool
        let order: Int?
    }

    struct LaunchTarget: Equatable {
        let primary: BuildableTarget
        let extensionHost: Target?
    }

    struct Profile: Equatable {
        let buildOnlyTargets: [BuildableTarget]
        let commandLineArguments: [String]
        let customWorkingDirectory: String?
        let environmentVariables: [EnvironmentVariable]
        let launchTarget: LaunchTarget?
        let useRunArgsAndEnv: Bool
        let xcodeConfiguration: String?
    }

    struct Test: Equatable {
        let buildOnlyTargets: [BuildableTarget]
        let commandLineArguments: [String]
        let enableAddressSanitizer: Bool
        let enableThreadSanitizer: Bool
        let enableUBSanitizer: Bool
        let environmentVariables: [EnvironmentVariable]
        let testTargets: [BuildableTarget]
        let useRunArgsAndEnv: Bool
        let xcodeConfiguration: String?
    }

    struct Run: Equatable {
        let buildOnlyTargets: [BuildableTarget]
        let commandLineArguments: [String]
        let customWorkingDirectory: String?
        let enableAddressSanitizer: Bool
        let enableThreadSanitizer: Bool
        let enableUBSanitizer: Bool
        let environmentVariables: [EnvironmentVariable]
        let launchTarget: LaunchTarget?
        let transitivePreviewReferences: [BuildableReference]
        let xcodeConfiguration: String?
    }

    let name: String
    let test: Test
    let run: Run
    let profile: Profile
}
