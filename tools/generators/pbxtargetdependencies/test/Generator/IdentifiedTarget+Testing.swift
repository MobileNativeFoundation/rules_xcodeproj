import Foundation

@testable import pbxtargetdependencies
@testable import PBXProj

extension IdentifiedTarget {
    static func mock(
        consolidationMapOutputPath: URL = URL(fileURLWithPath: "/tmp/out"),
        key: ConsolidatedTarget.Key,
        label: BazelLabel = "//some:target",
        productType: PBXProductType = .staticLibrary,
        name: String = "T",
        productPath: String = "some/libt.a",
        productBasename: String = "libt.a",
        uiTestHostName: String? = nil,
        identifier: Identifiers.Targets.Identifier = .init(
            pbxProjEscapedName: "T",
            subIdentifier: .init(shard: "00", hash: "00000000"),
            full: "T_ID /* T */",
            withoutComment: "T_ID"
        ),
        watchKitExtension: TargetID? = nil,
        dependencies: [TargetID] = []
    ) -> Self {
        return Self(
            consolidationMapOutputPath: consolidationMapOutputPath,
            key: key,
            label: label,
            productType: productType,
            name: name,
            productPath: productPath,
            productBasename: productBasename,
            uiTestHostName: uiTestHostName,
            identifier: identifier,
            watchKitExtension: watchKitExtension,
            dependencies: dependencies
        )
    }
}
