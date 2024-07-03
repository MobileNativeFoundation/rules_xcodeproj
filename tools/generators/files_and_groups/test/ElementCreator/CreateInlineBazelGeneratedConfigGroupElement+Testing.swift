import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateInlineBazelGeneratedConfigGroupElement.mock

extension ElementCreator.CreateInlineBazelGeneratedConfigGroupElement {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let path: String
            let bazelPath: BazelPath
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
                bazelPath,
                childIdentifiers,
                createIdentifier
            in
                mockTracker.called.append(.init(
                    name: name,
                    path: path,
                    bazelPath: bazelPath,
                    childIdentifiers: childIdentifiers
                ))
                return element
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateInlineBazelGeneratedConfigGroupElement.stub

extension ElementCreator.CreateInlineBazelGeneratedConfigGroupElement {
    static func stub(element: Element) -> Self {
        let (stub, _) = mock(element: element)
        return stub
    }
}
