import Foundation
import XcodeProj

extension PBXTarget {
    var buildableName: String {
        product?.path ?? name
    }

    func createBuildableReference(
        referencedContainer: String
    ) throws -> XCScheme.BuildableReference {
        .init(
            referencedContainer: referencedContainer,
            blueprint: self,
            buildableName: buildableName,
            blueprintName: name
        )
    }

    var schemeName: String {
        name
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }

    var isTestable: Bool {
        productType?.isTestBundle ?? false
    }

    var isLaunchable: Bool {
        productType?.isLaunchable ?? false
    }

    var defaultBuildConfigurationName: String {
        buildConfigurationList?.buildConfigurations.first?.name ??
            "Debug"
    }
}

extension Dictionary where Value: PBXTarget {
    func nativeTarget(_ targetID: Self.Key) -> PBXNativeTarget? {
        self[targetID] as? PBXNativeTarget
    }
}
