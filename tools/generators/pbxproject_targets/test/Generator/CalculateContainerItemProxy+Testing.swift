import PBXProj

@testable import pbxproject_targets

// MARK: - Generator.CalculateContainerItemProxy.mock

extension Generator.CalculateContainerItemProxy {
    final class MockTracker {
        struct Called: Equatable {
            let identifier: Identifiers.Targets.Identifier
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [String]

        init(results: [String]) {
            self.results = results.reversed()
        }

        func nextResult() -> String {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(contents: [String]) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: contents)

        let mocked = Self(
            callable: { identifier in
                mockTracker.called.append(.init(identifier: identifier))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}
