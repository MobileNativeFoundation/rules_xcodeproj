import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateVersionGroup.mock

extension ElementCreator.CreateVersionGroup {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let nodeChildren: [PathTreeNode]
            let parentBazelPath: BazelPath
            let bazelPathType: BazelPathType
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
                name,
                nodeChildren,
                parentBazelPath,
                bazelPathType,
                createFile,
                createIdentifier,
                createVersionGroupElement,
                collectBazelPaths,
                selectedModelVersions
            in
                mockTracker.called.append(.init(
                    name: name,
                    nodeChildren: nodeChildren,
                    parentBazelPath: parentBazelPath,
                    bazelPathType: bazelPathType
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
