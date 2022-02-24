import PathKit
import XcodeProj

struct Project: Equatable, Decodable {
    let name: String
    let buildSettings: [String: BuildSetting]
    var targets: [TargetID: Target]
    let potentialTargetMerges: [TargetID: Set<TargetID>]
    let requiredLinks: Set<Path>
    let extraFiles: Set<Path>
}

struct Target: Equatable, Decodable {
    let name: String
    let label: String
    let configuration: String
    let product: Product
    var buildSettings: [String: BuildSetting]
    var srcs: Set<Path>
    var links: Set<Path>
    var dependencies: Set<TargetID>
}

struct Product: Equatable, Decodable {
    let type: PBXProductType
    let name: String
    let path: Path
}
