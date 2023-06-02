import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.ResolveSymlink.mock

extension ElementCreator.ResolveSymlink {
    final class MockTracker {
        struct Called: Equatable {
            let path: String
        }

        fileprivate(set) var called: [Called] = []
    }

    static func mock(
        symlinkDest: String?
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker()

        let mocked = Self(
            callable: { path in
                mockTracker.called.append(.init(path: path))
                return symlinkDest
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.ResolveSymlink.stub

extension ElementCreator.ResolveSymlink {
    static func stub(symlinkDest: String?) -> Self {
        let (stub, _) = mock(symlinkDest: symlinkDest)
        return stub
    }
}
