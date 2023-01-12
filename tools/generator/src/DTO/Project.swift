struct Project: Equatable {
    let name: String
    let bazelConfig: String
    let generatorLabel: BazelLabel
    let runnerLabel: BazelLabel
    let configuration: String
    let minimumXcodeVersion: SemanticVersion
    let buildSettings: [String: BuildSetting]
    var targets: [TargetID: Target] = [:]
    let replacementLabels: [TargetID: BazelLabel]
    let targetHosts: [TargetID: [TargetID]]
    let args: [TargetID: [String]]
    let envs: [TargetID: [String: String]]
    let extraFiles: Set<FilePath>
    let schemeAutogenerationMode: SchemeAutogenerationMode
    let customXcodeSchemes: [XcodeScheme]
    let forceBazelDependencies: Bool
    let indexImport: String
    let preBuildScript: String?
    let postBuildScript: String?
}

extension Project: Decodable {
    enum CodingKeys: String, CodingKey {
        case name
        case bazelConfig
        case generatorLabel
        case runnerLabel
        case configuration
        case minimumXcodeVersion
        case buildSettings
        case replacementLabels
        case targetHosts
        case envs
        case args
        case extraFiles
        case schemeAutogenerationMode
        case customXcodeSchemes
        case forceBazelDependencies
        case indexImport
        case preBuildScript
        case postBuildScript
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        bazelConfig = try container.decode(String.self, forKey: .bazelConfig)
        generatorLabel = try container
            .decode(BazelLabel.self, forKey: .generatorLabel)
        runnerLabel = try container
            .decode(BazelLabel.self, forKey: .runnerLabel)
        configuration = try container
            .decode(String.self, forKey: .configuration)
        minimumXcodeVersion = try container
            .decode(SemanticVersion.self, forKey: .minimumXcodeVersion)
        buildSettings = try container
            .decode([String: BuildSetting].self, forKey: .buildSettings)
        replacementLabels = try container
            .decode([TargetID: BazelLabel].self, forKey: .replacementLabels)
        targetHosts = try container
            .decode([TargetID: [TargetID]].self, forKey: .targetHosts)
        args = try container
            .decode([TargetID: [String]].self, forKey: .args)
        envs = try container
            .decode([TargetID: [String: String]].self, forKey: .envs)
        extraFiles = try container
            .decode(Set<FilePath>.self, forKey: .extraFiles)
        schemeAutogenerationMode = try container
            .decode(SchemeAutogenerationMode.self, forKey: .schemeAutogenerationMode)
        customXcodeSchemes = try container
            .decode([XcodeScheme].self, forKey: .customXcodeSchemes)
        forceBazelDependencies = try container
            .decode(Bool.self, forKey: .forceBazelDependencies)
        indexImport = try container
            .decode(String.self, forKey: .indexImport)
        preBuildScript = try container
            .decodeIfPresent(String.self, forKey: .preBuildScript)
        postBuildScript = try container
            .decodeIfPresent(String.self, forKey: .postBuildScript)
    }
}
