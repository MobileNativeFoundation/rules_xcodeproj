import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateGroupElement.mock

extension ElementCreator.CreateGroupElement {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let bazelPath: BazelPath
            let specialRootGroupType: SpecialRootGroupType?
            let childIdentifiers: [String]
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(
        element: Element,
        resolvedRepository: ResolvedRepository?
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = Self(
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier,
            callable: {
                name,
                bazelPath,
                specialRootGroupType,
                childIdentifiers,
                createAttributes,
                createIdentifier
            in
                mockTracker.called.append(.init(
                    name: name,
                    bazelPath: bazelPath,
                    specialRootGroupType: specialRootGroupType,
                    childIdentifiers: childIdentifiers
                ))
                return (
                    element: element,
                    resolvedRepository: resolvedRepository
                )
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateGroupElement.stub

extension ElementCreator.CreateGroupElement {
    static func stub(
        element: Element,
        resolvedRepository: ResolvedRepository?
    ) -> Self {
        let (stub, _) = mock(
            element: element,
            resolvedRepository: resolvedRepository
        )
        return stub
    }
}
