import PBXProj
import XCScheme

@testable import xcschemes

extension Target {
    static func mock(
        key: Target.Key,
        productType: PBXProductType = .staticLibrary,
        buildableReference: BuildableReference? = nil
    ) -> Self {
        return Self(
            key: key,
            productType: productType,
            buildableReference: buildableReference ?? .mock(targetKey: key)
        )
    }
}

private extension BuildableReference {
    static func mock(targetKey: Target.Key) -> Self {
        let name = targetKey.sortedIds.map(\.rawValue).joined(separator: "_")

        return Self(
            blueprintIdentifier: "\(name)_blueprintIdentifier",
            buildableName: "\(name)_buildableName",
            blueprintName: name,
            referencedContainer: "\(name)_referencedContainer"
        )
    }
}
