struct Project: Equatable, Decodable {
    let name: String
    let bazelWorkspaceName: String
    let bazelConfig: String
    let label: BazelLabel
    let configuration: String
    let buildSettings: [String: BuildSetting]
    var targets: [TargetID: Target]
    let replacementLabels: [TargetID: BazelLabel]
    let targetMerges: [TargetID: Set<TargetID>]
    let targetHosts: [TargetID: [TargetID]]
    let extraFiles: Set<FilePath>
    let schemeAutogenerationMode: SchemeAutogenerationMode
    let customXcodeSchemes: [XcodeScheme]
    let forceBazelDependencies: Bool
    let indexImport: FilePath
}
