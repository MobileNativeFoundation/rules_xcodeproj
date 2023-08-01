import PBXProj

@testable import pbxtargetdependencies

// MARK: - Generator.CreateContainerItemProxyObject.mock

extension Generator.CreateContainerItemProxyObject {
    final class MockTracker {
        struct Called: Equatable {
            let subIdentifier: Identifiers.Targets.SubIdentifier
            let dependencyIdentifier: Identifiers.Targets.Identifier
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
            callable: { subIdentifier, dependencyIdentifier in
                mockTracker.called.append(.init(
                    subIdentifier: subIdentifier,
                    dependencyIdentifier: dependencyIdentifier
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}
