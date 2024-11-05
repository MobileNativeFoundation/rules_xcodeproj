import PBXProj
import XCScheme

@testable import xcschemes

// MARK: - Generator.CreateTargetAutomaticSchemeInfos.mock

extension Generator.CreateTargetAutomaticSchemeInfos {
    final class MockTracker {
        struct Called: Equatable {
            let commandLineArguments: [CommandLineArgument]
            let customSchemeNames: Set<String>
            let environmentVariables: [EnvironmentVariable]
            let extensionHostIDs: [TargetID: [TargetID]]
            let target: Target
            let targetsByID: [TargetID: Target]
            let targetsByKey: [Target.Key: Target]
            let testActionAttributes: [String: String]
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
                    commandLineArguments,
                    customSchemeNames,
                    environmentVariables,
                    extensionHostIDs,
                    target,
                    targetsByID,
                    targetsByKey,
                    testActionAttributes,
                    _ in
                mockTracker.called.append(.init(
                    commandLineArguments: commandLineArguments,
                    customSchemeNames: customSchemeNames,
                    environmentVariables: environmentVariables,
                    extensionHostIDs: extensionHostIDs,
                    target: target,
                    targetsByID: targetsByID,
                    targetsByKey: targetsByKey,
                    testActionAttributes: testActionAttributes
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}
