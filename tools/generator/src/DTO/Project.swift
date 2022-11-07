struct Project: Equatable, Decodable {
    let name: String
    let bazelWorkspaceName: String
    let bazelConfig: String
    let generatorLabel: BazelLabel
    let runnerLabel: BazelLabel
    let configuration: String
    let buildSettings: [String: BuildSetting]
    var targets: [TargetID: Target]
    let linkerProductsMap: [FilePath: FilePath]
    let replacementLabels: [TargetID: BazelLabel]
    let targetHosts: [TargetID: [TargetID]]
    let envs: [TargetID: [String: String]]
    let extraFiles: Set<FilePath>
    let schemeAutogenerationMode: SchemeAutogenerationMode
    let customXcodeSchemes: [XcodeScheme]
    let forceBazelDependencies: Bool
    let indexImport: FilePath
    let preBuildScript: String?
    let postBuildScript: String?
}
