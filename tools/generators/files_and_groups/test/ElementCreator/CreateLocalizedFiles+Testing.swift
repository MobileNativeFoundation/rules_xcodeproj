import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateLocalizedFiles.mock

extension ElementCreator.CreateLocalizedFiles {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let nodeChildren: [PathTreeNode]
            let parentBazelPath: BazelPath
            let region: String
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(
        localizedFiles: [GroupChild.LocalizedFile]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = Self(
            collectBazelPaths: ElementCreator.Stubs.collectBazelPaths,
            createLocalizedFileElement:
                ElementCreator.Stubs.createLocalizedFileElement,
            callable: {
                name,
                nodeChildren,
                parentBazelPath,
                region,
                collectBazelPaths,
                createFileElement
            in
                mockTracker.called.append(.init(
                    name: name,
                    nodeChildren: nodeChildren,
                    parentBazelPath: parentBazelPath,
                    region: region
                ))
                return localizedFiles
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateLocalizedFiles.stub

extension ElementCreator.CreateLocalizedFiles {
    static func stub(localizedFiles: [GroupChild.LocalizedFile]) -> Self {
        let (stub, _) = mock(localizedFiles: localizedFiles)
        return stub
    }
}
