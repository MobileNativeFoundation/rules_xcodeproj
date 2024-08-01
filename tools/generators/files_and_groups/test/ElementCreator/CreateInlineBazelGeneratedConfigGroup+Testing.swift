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
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateInlineBazelGeneratedConfigGroup.stub

extension ElementCreator.CreateInlineBazelGeneratedConfigGroup {
    static func stub(groupChildElements: [GroupChild.ElementAndChildren]) -> Self {
        let (stub, _) = mock(groupChildElements: groupChildElements)
        return stub
    }
}
