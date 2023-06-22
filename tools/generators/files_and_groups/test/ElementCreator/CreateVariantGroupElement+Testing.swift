import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateVariantGroupElement.mock

extension ElementCreator.CreateVariantGroupElement {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let path: String
            let childIdentifiers: [String]
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(element: Element) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = Self(
            createIdentifier: ElementCreator.Stubs.createIdentifier,
            callable: {
                name,
                path,
                childIdentifiers,
                createIdentifier
            in
                mockTracker.called.append(.init(
                    name: name,
                    path: path,
                    childIdentifiers: childIdentifiers
                ))
                return element
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateVariantGroupElement.stub

extension ElementCreator.CreateVariantGroupElement {
    static func stub(element: Element) -> Self {
        let (stub, _) = mock(element: element)
        return stub
    }
}
