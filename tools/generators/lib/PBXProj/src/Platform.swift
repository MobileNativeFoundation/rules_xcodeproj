import ArgumentParser

public enum Platform: String, ExpressibleByArgument {
    public enum OS: Comparable {
        case macOS
        case iOS
        case tvOS
        case visionOS
        case watchOS
    }

    case macOS = "macosx"
    case iOSDevice = "iphoneos"
    case iOSSimulator = "iphonesimulator"
    case tvOSDevice = "appletvos"
    case tvOSSimulator = "appletvsimulator"
    case visionOSDevice = "xros"
    case visionOSSimulator = "xrsimulator"
    case watchOSDevice = "watchos"
    case watchOSSimulator = "watchsimulator"
}

extension Platform {
    private static let deviceEnvironment = "Device"
    private static let simulatorEnvironment = "Simulator"

    public var environment: String {
        switch self {
        case .macOS: return Self.deviceEnvironment
        case .iOSDevice: return Self.deviceEnvironment
        case .iOSSimulator: return Self.simulatorEnvironment
        case .tvOSDevice: return Self.deviceEnvironment
        case .tvOSSimulator: return Self.simulatorEnvironment
        case .visionOSDevice: return Self.deviceEnvironment
        case .visionOSSimulator: return Self.simulatorEnvironment
        case .watchOSDevice: return Self.deviceEnvironment
        case .watchOSSimulator: return Self.simulatorEnvironment
        }
    }

    public var os: OS {
        switch self {
        case .macOS: return .macOS
        case .iOSDevice, .iOSSimulator: return .iOS
        case .tvOSDevice, .tvOSSimulator: return .tvOS
        case .visionOSDevice, .visionOSSimulator: return .visionOS
        case .watchOSDevice, .watchOSSimulator: return .watchOS
        }
    }
}

// MARK: - Comparable

extension Platform: Comparable {
    public static func < (lhs: Platform, rhs: Platform) -> Bool {
        guard lhs != rhs else {
            return false
        }

        // Sort simulator first when platform has an associated simulator
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
        case (.visionOSSimulator, _): return true
        case (_, .visionOSSimulator): return false
        case (.visionOSDevice, _): return true
        case (_, .visionOSDevice): return false
        case (.watchOSSimulator, _): return true
        case (_, .watchOSSimulator): return false
        case (.watchOSDevice, _): return true
        case (_, .watchOSDevice): return false
        }
    }
}
