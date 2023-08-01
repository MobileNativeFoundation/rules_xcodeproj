import Foundation

@testable import pbxtargetdependencies
@testable import PBXProj

extension IdentifiedTarget {
    static func mock(
        consolidationMapOutputPath: URL = URL(fileURLWithPath: "/tmp/out"),
        key: ConsolidatedTarget.Key,
        name: String = "T",
        identifier: Identifiers.Targets.Identifier = .init(
            pbxProjEscapedName: "T",
            subIdentifier: .init(shard: "00", hash: "00000000"),
            full: "T_ID /* T */",
            withoutComment: "T_ID"
        ),
        dependencies: [TargetID] = []
    ) -> Self {
        return Self(
            consolidationMapOutputPath: consolidationMapOutputPath,
            key: key,
            name: name,
            identifier: identifier,
            dependencies: dependencies
        )
    }
}
