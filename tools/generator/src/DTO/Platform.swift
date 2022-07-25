struct Platform: Equatable, Hashable, Decodable {
    enum OS: String, Decodable {
        case macOS = "macos"
        case iOS = "ios"
        case tvOS = "tvos"
        case watchOS = "watchos"
    }

    let name: String
    let os: OS
    let arch: String
    let minimumOsVersion: String
    let minimumDeploymentOsVersion: String
    let environment: String?
}

extension Platform.OS {
    var deploymentTargetBuildSettingKey: String {
        switch self {
        case .macOS: return"MACOSX_DEPLOYMENT_TARGET"
        case .iOS: return "IPHONEOS_DEPLOYMENT_TARGET"
        case .tvOS: return "TVOS_DEPLOYMENT_TARGET"
        case .watchOS: return "WATCHOS_DEPLOYMENT_TARGET"
        }
    }
}

// MARK: - Comparable

extension Platform: Comparable {
    static func < (lhs: Platform, rhs: Platform) -> Bool {
        guard lhs.os == rhs.os else {
            return lhs.os < rhs.os
        }

        guard lhs.minimumOsVersion == rhs.minimumOsVersion else {
            return lhs.minimumOsVersion
                .compare(rhs.minimumOsVersion, options: .numeric)
                == .orderedAscending
        }

        guard lhs.environment == rhs.environment else {
            // Sort simulator first
            switch (lhs.environment, rhs.environment) {
            case ("Simulator", _): return true
            case (_, "Simulator"): return false
            case (nil, _): return true
            case (_, nil): return false
            case ("Device", _): return true
            case (_, "Device"): return false
            default: return false
            }
        }

        guard lhs.arch != "arm64" else {
            // Sort Apple Silicon first
            return rhs.arch != "arm64"
        }

        return lhs.arch < rhs.arch
    }
}

extension Platform.OS: Comparable {
    static func < (lhs: Platform.OS, rhs: Platform.OS) -> Bool {
        switch (lhs, rhs) {
        case (.macOS, _): return true
        case (_, .macOS): return false
        case (.iOS, _): return true
        case (_, .iOS): return false
        case (.tvOS, _): return true
        case (_, .tvOS): return false
        case (.watchOS, _): return true
        case (_, .watchOS): return false
        }
    }
}
