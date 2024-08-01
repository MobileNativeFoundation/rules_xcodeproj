import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateExternalRepositoriesGroup.mock

extension ElementCreator.CreateExternalRepositoriesGroup {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let nodeChildren: [PathTreeNode]
            let bazelPathType: BazelPathType
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [GroupChild.ElementAndChildren]

        init(results: [GroupChild.ElementAndChildren]) {
            self.results = results.reversed()
        }

        func nextResult() -> GroupChild.ElementAndChildren {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        groupChildElements: [GroupChild.ElementAndChildren]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: groupChildElements)

        let mocked = Self(
            createExternalRepositoriesGroupElement:
                ElementCreator.Stubs.createExternalRepositoriesGroupElement,
            createGroupChild: ElementCreator.Stubs.createGroupChild,
            createGroupChildElements:
                ElementCreator.Stubs.createGroupChildElements,
            callable: {
                name,
                nodeChildren,
                bazelPathType,
                createExternalRepositoriesGroupElement,
                createGroupChild,
                createGroupChildElements
            in
                mockTracker.called.append(.init(
                    name: name,
                    nodeChildren: nodeChildren,
                    bazelPathType: bazelPathType
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateExternalRepositoriesGroup.stub

extension ElementCreator.CreateExternalRepositoriesGroup {
    static func stub(
        groupChildElements: [GroupChild.ElementAndChildren]
    ) -> Self {
        let (stub, _) = mock(groupChildElements: groupChildElements)
        return stub
    }
}
