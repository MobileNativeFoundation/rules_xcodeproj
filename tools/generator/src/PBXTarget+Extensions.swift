import Foundation
import XcodeProj

public extension PBXTarget {
    var buildableName: String {
        return product?.path ?? name
    }

    func createBuildableReference(
        referencedContainer: String
    ) throws -> XCScheme.BuildableReference {
        return .init(
            referencedContainer: referencedContainer,
            blueprint: self,
            buildableName: buildableName,
            blueprintName: name
        )
    }

    var schemeName: String {
        return name
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }

    var isTestable: Bool {
        return productType?.isTestBundle ?? false
    }

    var isLaunchable: Bool {
        return productType?.isLaunchable ?? false
    }

    var defaultBuildConfigurationName: String {
        return buildConfigurationList?.buildConfigurations.first?.name ??
            "Debug"
    }
}
