import Foundation
import XcodeProj

public extension PBXTarget {
    func getBuildableName() throws -> String {
        guard let buildableName = productName else {
            throw PreconditionError(message: """
`productName` not set on target
""")
        }
        return buildableName
    }

    func createBuildableReference(
        referencedContainer: String
    ) throws -> XCScheme.BuildableReference {
        return .init(
            referencedContainer: referencedContainer,
            blueprint: self,
            buildableName: try getBuildableName(),
            blueprintName: name
        )
    }

    func getSchemeName() throws -> String {
        // GH371: Update XcodeProj to support slashes in the scheme name.
        // The XcodeProj write logic does not like slashes (/) in the scheme
        // name. It fails to write with a missing folder error.
        return try getBuildableName()
            .replacingOccurrences(of: "/", with: "_")
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
