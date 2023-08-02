import PBXProj

@testable import pbxtargetdependencies

// MARK: - Generator.CalculateTargetDependency.mock

extension Generator.CreateTargetDependencyObject {
    final class MockTracker {
        struct Called: Equatable {
            let subIdentifier: Identifiers.Targets.SubIdentifier
            let dependencyIdentifier: Identifiers.Targets.Identifier
            let containerItemProxyIdentifier: String
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [Object]

        init(results: [Object]) {
            self.results = results.reversed()
        }

        func nextResult() -> Object {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        objects: [Object]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: objects)

        let mocked = Self(
            callable: {
                subIdentifier,
                dependencyIdentifier,
                containerItemProxyIdentifier in
                mockTracker.called.append(.init(
                    subIdentifier: subIdentifier,
                    dependencyIdentifier: dependencyIdentifier,
                    containerItemProxyIdentifier: containerItemProxyIdentifier
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}
