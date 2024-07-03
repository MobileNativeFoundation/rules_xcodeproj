import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateVersionGroup.mock

extension ElementCreator.CreateVersionGroup {
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
            createFile: ElementCreator.Stubs.createFile,
            createIdentifier: ElementCreator.Stubs.createIdentifier,
            createVersionGroupElement:
                ElementCreator.Stubs.createVersionGroupElement,
            collectBazelPaths: ElementCreator.Stubs.collectBazelPaths,
            selectedModelVersions: [:],
            callable: {
                groupNode,
                name,
                parentBazelPath,
                specialRootGroupType,
                createFile,
                createIdentifier,
                createVersionGroupElement,
                collectBazelPaths,
                selectedModelVersions
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

// MARK: - ElementCreator.CreateVersionGroup.stub

extension ElementCreator.CreateVersionGroup {
    static func stub(groupChildElement: GroupChild.ElementAndChildren) -> Self {
        let (stub, _) = mock(groupChildElement: groupChildElement)
        return stub
    }
}
