import PBXProj

@testable import pbxtargetdependencies

// MARK: - Generator.CreateTargetAttributesContent.mock

extension Generator.CreateTargetAttributesContent {
    final class MockTracker {
        struct Called: Equatable {
            let createdOnToolsVersion: String
            let testHostIdentifierWithoutComment: String?
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [String]

        init(results: [String]) {
            self.results = results.reversed()
        }

        func nextResult() -> String {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(contents: [String]) -> (mock: Self, tracker: MockTracker) {
        let mockTracker = MockTracker(results: contents)

        let mocked = Self(
            callable: {
                    createdOnToolsVersion, testHostIdentifierWithoutComment in
                mockTracker.called.append(.init(
                    createdOnToolsVersion: createdOnToolsVersion,
                    testHostIdentifierWithoutComment:
                        testHostIdentifierWithoutComment
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}
