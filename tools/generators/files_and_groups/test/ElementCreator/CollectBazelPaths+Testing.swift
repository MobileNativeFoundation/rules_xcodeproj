import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CollectBazelPaths.mock

extension ElementCreator.CollectBazelPaths {
    final class MockTracker {
        struct Called: Equatable {
            let node: PathTreeNode
            let bazelPath: BazelPath
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [[BazelPath]]

        init(results: [[BazelPath]]) {
            self.results = results.reversed()
        }

        func nextResult() -> [BazelPath] {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        bazelPaths: [[BazelPath]]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: bazelPaths)

        let mocked = Self(
            callable: { node, bazelPath in
                mockTracker.called.append(.init(
                    node: node,
                    bazelPath: bazelPath
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CollectBazelPaths.stub

extension ElementCreator.CollectBazelPaths {
    static func stub(bazelPaths: [[BazelPath]]) -> Self {
        let (stub, _) = mock(bazelPaths: bazelPaths)
        return stub
    }
}
