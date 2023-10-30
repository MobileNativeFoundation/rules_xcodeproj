import PBXProj
import XCScheme

@testable import xcschemes

// MARK: - Generator.CreateAutomaticSchemeInfo.mock

extension Generator.CreateAutomaticSchemeInfo {
    final class MockTracker {
        struct Called: Equatable {
            let commandLineArguments: [CommandLineArgument]
            let customSchemeNames: Set<String>
            let environmentVariables: [EnvironmentVariable]
            let extensionHost: Target?
            let target: Target
            let transitivePreviewReferences: [BuildableReference]
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
                    commandLineArguments,
                    customSchemeNames,
                    environmentVariables,
                    extensionHost,
                    target,
                    transitivePreviewReferences in
                mockTracker.called.append(.init(
                    commandLineArguments: commandLineArguments,
                    customSchemeNames: customSchemeNames,
                    environmentVariables: environmentVariables,
                    extensionHost: extensionHost,
                    target: target,
                    transitivePreviewReferences: transitivePreviewReferences
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
