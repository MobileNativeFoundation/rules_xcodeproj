import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateGroupChildElements.mock

extension ElementCreator.CreateGroupChildElements {
    final class MockTracker {
        struct Called: Equatable {
            let parentBazelPath: BazelPath
            let groupChildren: [GroupChild]
            let resolvedRepositories: [ResolvedRepository]
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(
        groupChildElements: GroupChildElements
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = Self(
            createVariantGroup: ElementCreator.Stubs.createVariantGroup,
            callable: {
                parentBazelPath,
                groupChildren,
                resolvedRepositories,
                createVariantGroup
            in
                mockTracker.called.append(.init(
                    parentBazelPath: parentBazelPath,
                    groupChildren: groupChildren,
                    resolvedRepositories: resolvedRepositories
                ))
                return groupChildElements
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateGroupChildElements.stub

extension ElementCreator.CreateGroupChildElements {
    static func stub(groupChildElements: GroupChildElements) -> Self {
        let (stub, _) = mock(groupChildElements: groupChildElements)
        return stub
    }
}
