import PBXProj

@testable import files_and_groups

// MARK: - ElementCreator.CreateVariantGroup.mock

extension ElementCreator.CreateVariantGroup {
    final class MockTracker {
        struct Called: Equatable {
            let name: String
            let parentBazelPath: BazelPath
            let localizedFiles: [GroupChild.LocalizedFile]
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [GroupChild.ElementAndChildren]

        init(results: [GroupChild.ElementAndChildren]) {
            self.results = results.reversed()
        }

        func nextResult() -> GroupChild.ElementAndChildren {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        groupChildElements: [GroupChild.ElementAndChildren]
    ) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: groupChildElements)

        let mocked = Self(
            createVariantGroupElement:
                ElementCreator.Stubs.createVariantGroupElement,
            callable: {
                name,
                parentBazelPath,
                localizedFiles,
                createVariantGroupElement
            in
                mockTracker.called.append(.init(
                    name: name,
                    parentBazelPath: parentBazelPath,
                    localizedFiles: localizedFiles
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}

// MARK: - ElementCreator.CreateVariantGroup.stub

extension ElementCreator.CreateVariantGroup {
    static func stub(
        groupChildElements: [GroupChild.ElementAndChildren]
    ) -> Self {
        let (stub, _) = mock(groupChildElements: groupChildElements)
        return stub
    }
}
