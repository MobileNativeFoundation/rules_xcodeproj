import Foundation
import XcodeProj

extension PBXTarget {
    var shouldCreateScheme: Bool {
        return productType?.shouldCreateScheme ?? true
    }

    var buildableName: String {
        return product?.path ?? name
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

extension Dictionary where Value: PBXTarget {
    func nativeTarget(_ targetID: Self.Key) -> PBXNativeTarget? {
        return self[targetID] as? PBXNativeTarget
    }
}
