import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateLocalizedFileElement.mock

extension ElementCreator.CreateLocalizedFileElement {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let path: String
            let ext: String?
            let bazelPath: BazelPath
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [Element]

        init(results: [Element]) {
            self.results = results.reversed()
        }

        func nextResult() -> Element {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        elements: [Element]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: elements)

        let mocked = Self(
            createIdentifier: ElementCreator.Stubs.createIdentifier,
            callable: {
                name,
                path,
                ext,
                bazelPath,
                createIdentifier
            in
                mockTracker.called.append(.init(
                    name: name,
                    path: path,
                    ext: ext,
                    bazelPath: bazelPath
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateLocalizedFileElement.stub

extension ElementCreator.CreateLocalizedFileElement {
    static func stub(elements: [Element]) -> Self {
        let (stub, _) = mock(elements: elements)
        return stub
    }
}
