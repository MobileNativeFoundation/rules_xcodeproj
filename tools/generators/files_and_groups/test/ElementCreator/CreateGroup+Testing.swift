import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateGroup.mock

extension ElementCreator.CreateGroup {
    final class MockTracker {
        struct Called: Equatable {
            let groupNode: PathTreeNode.Group
            let name: String
            let parentBazelPath: BazelPath
            let specialRootGroupType: SpecialRootGroupType?
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(
        groupChildElement: GroupChild.ElementAndChildren
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = Self(
            createGroupChildElements:
                ElementCreator.Stubs.createGroupChildElements,
            createGroupElement: ElementCreator.Stubs.createGroupElement,
            callable: {
                groupNode,
                name,
                parentBazelPath,
                specialRootGroupType,
                createGroupChild,
                createGroupChildElements,
                createGroupElement
            in
                mockTracker.called.append(.init(
                    groupNode: groupNode,
                    name: name,
                    parentBazelPath: parentBazelPath,
                    specialRootGroupType: specialRootGroupType
                ))
                return groupChildElement
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateGroup.stub

extension ElementCreator.CreateGroup {
    static func stub(groupChildElement: GroupChild.ElementAndChildren) -> Self {
        let (stub, _) = mock(groupChildElement: groupChildElement)
        return stub
    }
}
