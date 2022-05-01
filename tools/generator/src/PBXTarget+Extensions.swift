import Foundation
import XcodeProj

public extension PBXTarget {
    var buildableName: String {
        return productName ?? name
    }

    func createBuildableReference(
        referencedContainer: XcodeProjContainerReference
    ) -> XCScheme.BuildableReference {
        return .init(
            referencedContainer: "\(referencedContainer)",
            blueprint: self,
            buildableName: buildableName,
            blueprintName: name
        )
    }

    var schemeName: String {
        // GH371: Update XcodeProj to support slashes in the scheme name.
        // The XcodeProj write logic does not like slashes (/) in the scheme
        // name. It fails to write with a missing folder error.
        return buildableName.replacingOccurrences(of: "/", with: "_")
    }

    var isTestable: Bool {
        return productType?.isTestBundle ?? false
    }

    var isLaunchable: Bool {
        return productType?.isExecutable ?? false
    }

    var defaultBuildConfigurationName: String {
        return buildConfigurationList?.buildConfigurations.first?.name ??
            "Debug"
    }
}
