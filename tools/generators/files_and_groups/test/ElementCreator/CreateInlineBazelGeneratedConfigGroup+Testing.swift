import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateInlineBazelGeneratedConfigGroup.mock

extension ElementCreator.CreateInlineBazelGeneratedConfigGroup {
    final class MockTracker {
        struct Called: Equatable {
            let config: PathTreeNode.GeneratedFiles.Config
            let parentBazelPath: BazelPath
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
            createInlineBazelGeneratedConfigGroupElement:
                ElementCreator.Stubs
                    .createInlineBazelGeneratedConfigGroupElement,
            callable: {
                config,
                parentBazelPath,
                createGroupChild,
                createGroupChildElements,
                createInlineBazelGeneratedConfigGroupElement
            in
                mockTracker.called.append(.init(
                    config: config,
                    parentBazelPath: parentBazelPath
                ))
                return groupChildElement
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateInlineBazelGeneratedConfigGroup.stub

extension ElementCreator.CreateInlineBazelGeneratedConfigGroup {
    static func stub(groupChildElement: GroupChild.ElementAndChildren) -> Self {
        let (stub, _) = mock(groupChildElement: groupChildElement)
        return stub
    }
}
