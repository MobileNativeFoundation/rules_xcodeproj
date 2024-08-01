import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateInlineBazelGeneratedFiles.mock

extension ElementCreator.CreateInlineBazelGeneratedFiles {
    final class MockTracker {
        struct Called: Equatable {
            let generatedFiles: PathTreeNode.GeneratedFiles
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
            createInlineBazelGeneratedConfigGroup:
                ElementCreator.Stubs.createInlineBazelGeneratedConfigGroup,
            createInlineBazelGeneratedFilesElement:
                ElementCreator.Stubs.createInlineBazelGeneratedFilesElement,
            callable: {
                generatedFiles,
                createGroupChild,
                createGroupChildElements,
                createInlineBazelGeneratedConfigGroup,
                createInlineBazelGeneratedFilesElement
            in
                mockTracker.called.append(.init(
                    generatedFiles: generatedFiles
                ))
                return groupChildElement
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateInlineBazelGeneratedFiles.stub

extension ElementCreator.CreateInlineBazelGeneratedFiles {
    static func stub(groupChildElement: GroupChild.ElementAndChildren) -> Self {
        let (stub, _) = mock(groupChildElement: groupChildElement)
        return stub
    }
}
