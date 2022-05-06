import Foundation
import XcodeProj

public extension PBXTarget {
    func getBuildableName() throws -> String {
        guard let buildableName = (product?.path ?? productName) else {
            throw PreconditionError(message: """
`product` path and `productName` not set on target (\(name))
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
