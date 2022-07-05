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
    let schemeAutogenerationMode: SchemeAutogenerationMode
    let customXcodeSchemes: [XcodeScheme]?
}
