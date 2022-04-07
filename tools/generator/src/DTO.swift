import PathKit
import XcodeProj

struct Project: Equatable, Decodable {
    let name: String
    let label: String
    let buildSettings: [String: BuildSetting]
    var targets: [TargetID: Target]
    let potentialTargetMerges: [TargetID: Set<TargetID>]
    let requiredLinks: Set<FilePath>
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
    var frameworks: [FilePath]
    var modulemaps: [FilePath]
    var swiftmodules: [FilePath]
    let resourceBundles: Set<FilePath>
    var inputs: Inputs
    var links: Set<FilePath>
    var infoPlist: FilePath?
    var dependencies: Set<TargetID>
}

struct Product: Equatable, Decodable {
    let type: PBXProductType
    let name: String
    let path: FilePath
}

struct Platform: Equatable, Decodable {
    enum OS: String, Decodable {
        case macOS = "macos"
        case iOS = "ios"
        case tvOS = "tvos"
        case watchOS = "watchos"
    }

    let os: OS
    let arch: String
    let minimumOsVersion: String
    let environment: String?
}
