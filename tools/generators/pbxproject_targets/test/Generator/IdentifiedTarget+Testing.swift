import Foundation

@testable import pbxproject_targets
@testable import PBXProj

extension IdentifiedTarget {
    static func mock(
        consolidationMapOutputPath: URL = URL(fileURLWithPath: "/tmp/out"),
        key: ConsolidatedTarget.Key,
        identifier: Identifiers.Targets.Identifier = .init(
            name: "T",
            subIdentifier: .init(shard: "00", hash: "00000000"),
            full: "T_ID /* T */",
            withoutComment: "T_ID"
        ),
        dependencies: [TargetID] = []
    ) -> Self {
        return Self(
            consolidationMapOutputPath: consolidationMapOutputPath,
            key: key,
            identifier: identifier,
            dependencies: dependencies
        )
    }
}
