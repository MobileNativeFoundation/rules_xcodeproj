import PathKit
import XcodeProj

struct Project: Equatable, Decodable {
    let name: String
    let label: String
    let buildSettings: [String: BuildSetting]
    var targets: [TargetID: Target]
    let potentialTargetMerges: [TargetID: Set<TargetID>]
    let requiredLinks: Set<Path>
    let extraFiles: Set<FilePath>
}

struct Target: Equatable, Decodable {
    let name: String
    let label: String
    let configuration: String
    let platform: Platform
    let product: Product
    let testHost: TargetID?
    var buildSettings: [String: BuildSetting]
    var inputs: Inputs
    var links: Set<Path>
    var dependencies: Set<TargetID>
}

struct Product: Equatable, Decodable {
    let type: PBXProductType
    let name: String
    let path: Path
}

struct Platform: Equatable, Decodable {
    let os: String
    let arch: String
    let minimumOsVersion: String
    let environment: String?
}
