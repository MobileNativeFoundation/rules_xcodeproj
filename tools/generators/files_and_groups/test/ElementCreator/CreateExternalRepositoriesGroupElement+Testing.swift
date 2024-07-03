import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateExternalRepositoriesGroupElement.mock

extension ElementCreator.CreateExternalRepositoriesGroupElement {
    final class MockTracker {
        struct Called: Equatable {
            let childIdentifiers: [String]
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(element: Element) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = Self(
            callable: { childIdentifiers in
                mockTracker.called.append(.init(
                    childIdentifiers: childIdentifiers
                ))
                return element
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateExternalRepositoriesGroupElement.stub

extension ElementCreator.CreateExternalRepositoriesGroupElement {
    static func stub(element: Element) -> Self {
        let (stub, _) = mock(element: element)
        return stub
    }
}
