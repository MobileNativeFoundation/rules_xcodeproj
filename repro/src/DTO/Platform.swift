struct Platform: Equatable, Hashable, Decodable {
    enum OS: String, Decodable {
        case macOS = "macos"
        case iOS = "ios"
        case tvOS = "tvos"
        case watchOS = "watchos"
    }

    enum Variant: String, Decodable {
        case macOS = "macosx"
        case iOSDevice = "iphoneos"
        case iOSSimulator = "iphonesimulator"
        case tvOSDevice = "appletvos"
        case tvOSSimulator = "appletvsimulator"
        case watchOSDevice = "watchos"
        case watchOSSimulator = "watchsimulator"
    }

    let os: OS
    let variant: Variant
    let arch: String
    let minimumOsVersion: SemanticVersion
}

extension Platform {
    var swiftTriple: String {
        return """
\(arch)-apple-\(variant.swiftTriplePrefix)\(variant.tripleSuffix)
"""
    }

    var targetTriple: String {
        let osVersion = minimumOsVersion.full

        return """
\(arch)-apple-\(variant.targetTriplePrefix)\(osVersion)\(variant.tripleSuffix)
"""
    }
}

extension Platform.OS {
    var deploymentTargetBuildSettingKey: String {
        switch self {
        case .macOS: return "MACOSX_DEPLOYMENT_TARGET"
        case .iOS: return "IPHONEOS_DEPLOYMENT_TARGET"
        case .tvOS: return "TVOS_DEPLOYMENT_TARGET"
        case .watchOS: return "WATCHOS_DEPLOYMENT_TARGET"
        }
    }
}

extension Platform.Variant {
    private static let deviceEnvironment = "Device"
    private static let simulatorEnvironment = "Simulator"

    var environment: String {
        switch self {
        case .macOS: return Self.deviceEnvironment
        case .iOSDevice: return Self.deviceEnvironment
        case .iOSSimulator: return Self.simulatorEnvironment
        case .tvOSDevice: return Self.deviceEnvironment
        case .tvOSSimulator: return Self.simulatorEnvironment
        case .watchOSDevice: return Self.deviceEnvironment
        case .watchOSSimulator: return Self.simulatorEnvironment
        }
    }

    var swiftTriplePrefix: String {
        switch self {
        case .macOS: return "macos"
        case .iOSDevice: return "ios"
        case .iOSSimulator: return "ios"
        case .tvOSDevice: return "tvos"
        case .tvOSSimulator: return "tvos"
        case .watchOSDevice: return "watchos"
        case .watchOSSimulator: return "watchos"
        }
    }

    var targetTriplePrefix: String {
        switch self {
        case .macOS: return "macosx"
        case .iOSDevice: return "ios"
        case .iOSSimulator: return "ios"
        case .tvOSDevice: return "tvos"
        case .tvOSSimulator: return "tvos"
        case .watchOSDevice: return "watchos"
        case .watchOSSimulator: return "watchos"
        }
    }

    var tripleSuffix: String {
        switch self {
        case .macOS: return ""
        case .iOSDevice: return ""
        case .iOSSimulator: return "-simulator"
        case .tvOSDevice: return ""
        case .tvOSSimulator: return "-simulator"
        case .watchOSDevice: return ""
        case .watchOSSimulator: return "-simulator"
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
            return lhs.minimumOsVersion < rhs.minimumOsVersion
        }

        guard lhs.variant == rhs.variant else {
            return lhs.variant < rhs.variant
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

extension Platform.Variant: Comparable {
    static func < (lhs: Platform.Variant, rhs: Platform.Variant) -> Bool {
        // Sort simulator first
        switch (lhs, rhs) {
        case (.macOS, _): return true
        case (_, .macOS): return false
        case (.iOSSimulator, _): return true
        case (_, .iOSSimulator): return false
        case (.iOSDevice, _): return true
        case (_, .iOSDevice): return false
        case (.tvOSSimulator, _): return true
        case (_, .tvOSSimulator): return false
        case (.tvOSDevice, _): return true
        case (_, .tvOSDevice): return false
        case (.watchOSSimulator, _): return true
        case (_, .watchOSSimulator): return false
        case (.watchOSDevice, _): return true
        case (_, .watchOSDevice): return false
        }
    }
}
