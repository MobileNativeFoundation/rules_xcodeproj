import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateIdentifier.mock

extension ElementCreator.CreateIdentifier {
    final class MockTracker {
        struct Called: Equatable {
            let path: String
            let type: Identifiers.FilesAndGroups.ElementType
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(
        identifier: String
    ) -> (mock: ElementCreator.CreateIdentifier, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = ElementCreator.CreateIdentifier(
            callable: { path, type, _ in
                mockTracker.called.append(.init(
                    path: path,
                    type: type
                ))
                return identifier
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateIdentifier.stub

extension ElementCreator.CreateIdentifier {
    static func stub(identifier: String) -> ElementCreator.CreateIdentifier {
        let (stub, _) = mock(identifier: identifier)
        return stub
    }
}
