import PathKit
import XcodeProj

struct Project: Equatable, Decodable {
    let name: String
    let bazelWorkspaceName: String
    let label: String
    let configuration: String
    let buildSettings: [String: BuildSetting]
    var targets: [TargetID: Target]
    let targetMerges: [TargetID: Set<TargetID>]
    let invalidTargetMerges: [TargetID: Set<TargetID>]
    let extraFiles: Set<FilePath>
}

struct Target: Equatable, Decodable {
    let name: String
    let label: String
    let configuration: String
    var packageBinDir: Path
    let platform: Platform
    let product: Product
    var isSwift: Bool
    let testHost: TargetID?
    var buildSettings: [String: BuildSetting]
    var searchPaths: SearchPaths
    var modulemaps: [FilePath]
    var swiftmodules: [FilePath]
    let resourceBundles: Set<FilePath>
    var inputs: Inputs
    var linkerInputs: LinkerInputs
    var infoPlist: FilePath?
    var entitlements: FilePath?
    var dependencies: Set<TargetID>
    var outputs: Outputs
}

struct Product: Equatable, Decodable {
    let type: PBXProductType
    let name: String
    let path: FilePath
}

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
    let environment: String?
}

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
