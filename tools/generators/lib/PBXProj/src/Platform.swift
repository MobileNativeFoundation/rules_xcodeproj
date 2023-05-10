import ArgumentParser

public enum Platform: String, ExpressibleByArgument {
    case macOS = "macosx"
    case iOSDevice = "iphoneos"
    case iOSSimulator = "iphonesimulator"
    case tvOSDevice = "appletvos"
    case tvOSSimulator = "appletvsimulator"
    case watchOSDevice = "watchos"
    case watchOSSimulator = "watchsimulator"
}

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
        case (.watchOSSimulator, _): return true
        case (_, .watchOSSimulator): return false
        case (.watchOSDevice, _): return true
        case (_, .watchOSDevice): return false
        }
    }
}
