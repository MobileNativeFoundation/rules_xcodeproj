import PathKit

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
    var inputs: Inputs
    var linkerInputs: LinkerInputs
    var infoPlist: FilePath?
    var entitlements: FilePath?
    let resourceBundleDependencies: Set<TargetID>
    var dependencies: Set<TargetID>
    var outputs: Outputs
}

extension Target {
    var allDependencies: Set<TargetID> {
        return dependencies.union(resourceBundleDependencies)
    }
}
