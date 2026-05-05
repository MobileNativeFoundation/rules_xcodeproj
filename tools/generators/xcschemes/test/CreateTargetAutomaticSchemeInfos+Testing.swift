import PBXProj
import XCScheme

@testable import xcschemes

// MARK: - Generator.CreateTargetAutomaticSchemeInfos.mock

extension Generator.CreateTargetAutomaticSchemeInfos {
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
            let extensionHostIDs: [TargetID: [TargetID]]
            let runPostActions: [AutogenerationConfig.Action]
            let runPreActions: [AutogenerationConfig.Action]
            let target: Target
            let testPostActions: [AutogenerationConfig.Action]
            let testPreActions: [AutogenerationConfig.Action]
            let targetsByID: [TargetID: Target]
            let targetsByKey: [Target.Key: Target]
            let testOptions: SchemeInfo.Test.Options?
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [[SchemeInfo]]

        init(results: [[SchemeInfo]]) {
            self.results = results.reversed()
        }

        func nextResult() -> [SchemeInfo] {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        targetSchemeInfos: [[SchemeInfo]]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: targetSchemeInfos)

        let mocked = Self(
            createAutomaticSchemeInfo:
                Generator.Stubs.createAutomaticSchemeInfo,
            callable: {
                    buildPostActions,
                    buildPreActions,
                    buildRunPostActionsOnFailure,
                    profilePostActions,
                    profilePreActions,
                    commandLineArguments,
                    customSchemeNames,
                    environmentVariables,
                    extensionHostIDs,
                    runPostActions,
                    runPreActions,
                    target,
                    targetsByID,
                    targetsByKey,
                    testPostActions,
                    testPreActions,
                    testOptions,
                    _ in
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
                    extensionHostIDs: extensionHostIDs,
                    runPostActions: runPostActions,
                    runPreActions: runPreActions,
                    target: target,
                    testPostActions: testPostActions,
                    testPreActions: testPreActions,
                    targetsByID: targetsByID,
                    targetsByKey: targetsByKey,
                    testOptions: testOptions
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}
