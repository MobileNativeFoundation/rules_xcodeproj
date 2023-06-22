import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateLocalizedFiles.mock

extension ElementCreator.CreateLocalizedFiles {
    final class MockTracker {
        struct Called: Equatable {
            let node: PathTreeNode
            let parentBazelPath: BazelPath
            let specialRootGroupType: SpecialRootGroupType?
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
            createFileElement:
                ElementCreator.Stubs.createFileElement,
            callable: {
                node,
                parentBazelPath,
                specialRootGroupType,
                region,
                collectBazelPaths,
                createFileElement
            in
                mockTracker.called.append(.init(
                    node: node,
                    parentBazelPath: parentBazelPath,
                    specialRootGroupType: specialRootGroupType,
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
