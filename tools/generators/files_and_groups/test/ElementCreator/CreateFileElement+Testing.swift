import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateFileElement.mock

extension ElementCreator.CreateFileElement {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let ext: String?
            let bazelPath: BazelPath
            let specialRootGroupType: SpecialRootGroupType?
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results:
            [(element: Element, resolvedRepository: ResolvedRepository?)]

        init(
            results:
                [(element: Element, resolvedRepository: ResolvedRepository?)]
        ) {
            self.results = results.reversed()
        }

        func nextResult(
        ) -> (element: Element, resolvedRepository: ResolvedRepository?) {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        results: [(element: Element, resolvedRepository: ResolvedRepository?)]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: results)

        let mocked = Self(
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier,
            callable: {
                name,
                ext,
                bazelPath,
                specialRootGroupType,
                createAttributes,
                createIdentifier
            in
                mockTracker.called.append(.init(
                    name: name,
                    ext: ext,
                    bazelPath: bazelPath,
                    specialRootGroupType: specialRootGroupType
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateFileElement.stub

extension ElementCreator.CreateFileElement {
    static func stub(
        results: [(element: Element, resolvedRepository: ResolvedRepository?)]
    ) -> Self {
        let (stub, _) = mock(results: results)
        return stub
    }
}
