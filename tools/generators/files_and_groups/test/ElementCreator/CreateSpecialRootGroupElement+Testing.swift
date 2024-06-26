import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateSpecialRootGroupElement.mock

extension ElementCreator.CreateSpecialRootGroupElement {
    final class MockTracker {
        struct Called: Equatable {
            let specialRootGroupType: SpecialRootGroupType
            let childIdentifiers: [String]
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(element: Element, createIdentifier: ElementCreator.CreateIdentifier) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = Self(
            createIdentifier: createIdentifier,
            callable: { specialRootGroupType, childIdentifiers, useRootStableIdentifiers, createIdentifier, bazelPath in
                mockTracker.called.append(.init(
                    specialRootGroupType: specialRootGroupType,
                    childIdentifiers: childIdentifiers
                ))
                return element
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateSpecialRootGroupElement.stub

extension ElementCreator.CreateSpecialRootGroupElement {
    static func stub(element: Element) -> Self {
        let (stub, _) = mock(element: element, createIdentifier: ElementCreator.Stubs.createIdentifier)
        return stub
    }
}
