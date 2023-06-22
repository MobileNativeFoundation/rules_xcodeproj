import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateFile.mock

extension ElementCreator.CreateFile {
    final class MockTracker {
        struct Called: Equatable {
            let node: PathTreeNode
            let bazelPath: BazelPath
            let specialRootGroupType: SpecialRootGroupType?
            let identifierForBazelPaths: String?
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
        groupChildElement: [GroupChild.ElementAndChildren]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: groupChildElement)

        let mocked = Self(
            collectBazelPaths: ElementCreator.Stubs.collectBazelPaths,
            createFileElement: ElementCreator.Stubs.createFileElement,
            callable: {
                node,
                bazelPath,
                specialRootGroupType,
                identifierForBazelPaths,
                collectBazelPaths,
                createFileElement
            in
                mockTracker.called.append(.init(
                    node: node,
                    bazelPath: bazelPath,
                    specialRootGroupType: specialRootGroupType,
                    identifierForBazelPaths: identifierForBazelPaths
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateElement.stub

extension ElementCreator.CreateFile {
    static func stub(
        groupChildElement: [GroupChild.ElementAndChildren]
    ) -> Self {
        let (stub, _) = mock(groupChildElement: groupChildElement)
        return stub
    }
}
