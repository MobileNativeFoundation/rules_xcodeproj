import PBXProj

@testable import pbxtargetdependencies

// MARK: - Generator.CreateTargetSubIdentifier.mock

extension Generator.CreateTargetSubIdentifier {
    final class MockTracker {
        struct Called: Equatable {
            let targetId: TargetID
            let shard: UInt8
        }

        fileprivate(set) var called: [Called] = []

        fileprivate var results: [Identifiers.Targets.SubIdentifier]

        init(results: [Identifiers.Targets.SubIdentifier]) {
            self.results = results.reversed()
        }

        func nextResult() -> Identifiers.Targets.SubIdentifier {
            guard let result = results.popLast() else {
                preconditionFailure("Called too many times")
            }
            return result
        }
    }

    static func mock(
        subIdentifiers: [Identifiers.Targets.SubIdentifier]
    ) -> (mock: Generator.CreateTargetSubIdentifier, tracker: MockTracker) {
        let mockTracker = MockTracker(results: subIdentifiers)

        let mocked = Generator.CreateTargetSubIdentifier(
            callable: { targetId, shard, _ in
                mockTracker.called.append(.init(
                    targetId: targetId,
                    shard: shard
                ))
                return mockTracker.nextResult()
            }
        )

        return (mocked, mockTracker)
    }
}
