import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateInlineBazelGeneratedFilesElement.mock

extension ElementCreator.CreateInlineBazelGeneratedFilesElement {
    final class MockTracker {
        struct Called: Equatable {
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
                path,
                childIdentifiers,
                createIdentifier
            in
                mockTracker.called.append(.init(
                    path: path,
                    childIdentifiers: childIdentifiers
                ))
                return element
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateInlineBazelGeneratedFilesElement.stub

extension ElementCreator.CreateInlineBazelGeneratedFilesElement {
    static func stub(element: Element) -> Self {
        let (stub, _) = mock(element: element)
        return stub
    }
}
