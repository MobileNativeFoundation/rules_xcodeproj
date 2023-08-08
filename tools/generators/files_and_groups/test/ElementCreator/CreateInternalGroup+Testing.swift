import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateInternalGroup.mock

extension ElementCreator.CreateInternalGroup {
    final class MockTracker {
        struct Called: Equatable {
            let installPath: String
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [GroupChild]

        init(results: [GroupChild]) {
            self.results = results.reversed()
        }

        func nextResult() -> GroupChild {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        groupChildren: [GroupChild]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: groupChildren)

        let mocked = Self(
            callable: { installPath in
                mockTracker.called.append(.init(
                    installPath: installPath
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateInternalGroup.stub

extension ElementCreator.CreateInternalGroup {
    static func stub(groupChildren: [GroupChild]) -> Self {
        let (stub, _) = mock(groupChildren: groupChildren)
        return stub
    }
}
