import PBXProj
import XCScheme

@testable import xcschemes

// MARK: - Generator.CreateAutomaticSchemeInfo.mock

extension Generator.CreateAutomaticSchemeInfo {
    final class MockTracker {
        struct Called: Equatable {
            let buildPostActions: [AutogenerationConfig.Action]
            let buildPreActions: [AutogenerationConfig.Action]
            let buildRunPostActionsOnFailure: Bool
            let profilePostActions: [AutogenerationConfig.Action]
            let profilePreActions: [AutogenerationConfig.Action]
            let commandLineArguments: [CommandLineArgument]
            let customSchemeNames: Set<String>
            let environmentVariables: [EnvironmentVariable]
            let extensionHost: Target?
            let runPostActions: [AutogenerationConfig.Action]
            let runPreActions: [AutogenerationConfig.Action]
            let target: Target
            let testPostActions: [AutogenerationConfig.Action]
            let testPreActions: [AutogenerationConfig.Action]
            let testOptions: SchemeInfo.Test.Options?
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [SchemeInfo?]

        init(results: [SchemeInfo?]) {
            self.results = results.reversed()
        }

        func nextResult() -> SchemeInfo? {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        schemeInfos: [SchemeInfo?]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: schemeInfos)

        let mocked = Self(
            callable: {
                    buildPostActions,
                    buildPreActions,
                    buildRunPostActionsOnFailure,
                    profilePostActions,
                    profilePreActions,
                    commandLineArguments,
                    customSchemeNames,
                    environmentVariables,
                    extensionHost,
                    runPostActions,
                    runPreActions,
                    target,
                    testPostActions,
                    testPreActions,
                    testOptions in
                mockTracker.called.append(.init(
                    buildPostActions: buildPostActions,
                    buildPreActions: buildPreActions,
                    buildRunPostActionsOnFailure:
                        buildRunPostActionsOnFailure,
                    profilePostActions: profilePostActions,
                    profilePreActions: profilePreActions,
                    commandLineArguments: commandLineArguments,
                    customSchemeNames: customSchemeNames,
                    environmentVariables: environmentVariables,
                    extensionHost: extensionHost,
                    runPostActions: runPostActions,
                    runPreActions: runPreActions,
                    target: target,
                    testPostActions: testPostActions,
                    testPreActions: testPreActions,
                    testOptions: testOptions
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - Generator.CreateAutomaticSchemeInfo.stub

extension Generator.CreateAutomaticSchemeInfo {
    static func stub(schemeInfos: [SchemeInfo?]) -> Self {
        let (stub, _) = mock(schemeInfos: schemeInfos)
        return stub
    }
}
