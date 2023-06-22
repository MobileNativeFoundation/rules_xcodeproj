import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateSpecialRootGroup.mock

extension ElementCreator.CreateSpecialRootGroup {
    final class MockTracker {
        struct Called: Equatable {
            let node: PathTreeNode
            let specialRootGroupType: SpecialRootGroupType
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
            createGroupChild: ElementCreator.Stubs.createGroupChild,
            createGroupChildElements:
                ElementCreator.Stubs.createGroupChildElements,
            createSpecialRootGroupElement: ElementCreator.Stubs.createSpecialRootGroupElement,
            callable: {
                node,
                specialRootGroupType,
                createGroupChild,
                createGroupChildElements,
                createSpecialRootGroupElement
            in
                mockTracker.called.append(.init(
                    node: node,
                    specialRootGroupType: specialRootGroupType
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateSpecialRootGroup.stub

extension ElementCreator.CreateSpecialRootGroup {
    static func stub(
        groupChildElements: [GroupChild.ElementAndChildren]
    ) -> Self {
        let (stub, _) = mock(groupChildElements: groupChildElements)
        return stub
    }
}
