import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateVersionGroupElement.mock

extension ElementCreator.CreateVersionGroupElement {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let bazelPath: BazelPath
            let specialRootGroupType: SpecialRootGroupType?
            let identifier: String
            let childIdentifiers: [String]
            let selectedChildIdentifier: String?
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
            callable: {
                name,
                bazelPath,
                specialRootGroupType,
                identifier,
                childIdentifiers,
                selectedChildIdentifier,
                createAttributes
            in
                mockTracker.called.append(.init(
                    name: name,
                    bazelPath: bazelPath,
                    specialRootGroupType: specialRootGroupType,
                    identifier: identifier,
                    childIdentifiers: childIdentifiers,
                    selectedChildIdentifier: selectedChildIdentifier
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

// MARK: - ElementCreator.CreateVersionGroupElement.stub

extension ElementCreator.CreateVersionGroupElement {
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
