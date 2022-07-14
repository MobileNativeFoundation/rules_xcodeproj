struct Project: Equatable, Decodable {
    let name: String
    let bazelWorkspaceName: String
    let label: BazelLabel
    let configuration: String
    let buildSettings: [String: BuildSetting]
    var targets: [TargetID: Target]
    let targetMerges: [TargetID: Set<TargetID>]
    let targetHosts: [TargetID: [TargetID]]
    let extraFiles: Set<FilePath>
    let schemeAutogenerationMode: SchemeAutogenerationMode
    let customXcodeSchemes: [XcodeScheme]
}
