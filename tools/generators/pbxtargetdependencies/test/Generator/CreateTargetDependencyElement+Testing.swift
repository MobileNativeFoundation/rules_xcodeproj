import PBXProj

@testable import pbxtargetdependencies

// MARK: - Generator.CalculateTargetDependency.mock

extension Generator.CreateTargetDependencyElement {
    final class MockTracker {
        struct Called: Equatable {
            let subIdentifier: Identifiers.Targets.SubIdentifier
            let dependencyIdentifier: Identifiers.Targets.Identifier
            let containerItemProxyIdentifier: String
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [Element]

        init(results: [Element]) {
            self.results = results.reversed()
        }

        func nextResult() -> Element {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        elements: [Element]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: elements)

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
