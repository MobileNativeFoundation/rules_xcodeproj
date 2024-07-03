import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateFile.mock

extension ElementCreator.CreateFile {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let isFolder: Bool
            let bazelPath: BazelPath
            let bazelPathType: BazelPathType
            let transitiveBazelPaths: [BazelPath]
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
            createFileElement: ElementCreator.Stubs.createFileElement,
            callable: {
                name,
                isFolder,
                bazelPath,
                bazelPathType,
                transitiveBazelPaths,
                identifierForBazelPaths,
                createFileElement
            in
                mockTracker.called.append(.init(
                    name: name,
                    isFolder: isFolder,
                    bazelPath: bazelPath,
                    bazelPathType: bazelPathType,
                    transitiveBazelPaths: transitiveBazelPaths,
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
