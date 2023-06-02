import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateGroupChild.mock

extension ElementCreator.CreateGroupChild {
    final class MockTracker {
        struct Called: Equatable {
            let node: PathTreeNode
            let parentBazelPath: BazelPath
            let specialRootGroupType: SpecialRootGroupType?
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
        children: [GroupChild]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: children)

        let mocked = Self(
            createFile: ElementCreator.Stubs.createFile,
            createGroup: ElementCreator.Stubs.createGroup,
            createLocalizedFiles: ElementCreator.Stubs.createLocalizedFiles,
            createVersionGroup: ElementCreator.Stubs.createVersionGroup,
            callable: {
                node,
                parentBazelPath,
                specialRootGroupType,
                createGroupChild,
                createFile,
                createGroupElement,
                createLocalizedFiles,
                createVersionGroup
            in
                mockTracker.called.append(.init(
                    node: node,
                    parentBazelPath: parentBazelPath,
                    specialRootGroupType: specialRootGroupType
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateGroupChild.stub

extension ElementCreator.CreateGroupChild {
    static func stub(children: [GroupChild]) -> Self {
        let (stub, _) = mock(children: children)
        return stub
    }
}
