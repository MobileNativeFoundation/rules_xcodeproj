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
    var customXcodeSchemes: [XcodeScheme] = []
    let forceBazelDependencies: Bool
    let indexImport: String
    let preBuildScript: String?
    let postBuildScript: String?
}

extension Project: Decodable {
    enum CodingKeys: String, CodingKey {
        case name = "n"
        case bazelConfig = "B"
        case generatorLabel = "g"
        case runnerLabel = "R"
        case configuration = "c"
        case minimumXcodeVersion = "m"
        case buildSettings = "b"
        case replacementLabels = "r"
        case targetHosts = "t"
        case envs = "E"
        case args = "a"
        case extraFiles = "e"
        case schemeAutogenerationMode = "s"
        case forceBazelDependencies = "f"
        case indexImport = "i"
        case preBuildScript = "p"
        case postBuildScript = "P"
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
            .decodeIfPresent(
                [TargetID: BazelLabel].self,
                forKey: .replacementLabels
            ) ?? [:]
        targetHosts = try container
            .decodeIfPresent([TargetID: [TargetID]].self, forKey: .targetHosts)
            ?? [:]
        args = try container
            .decodeIfPresent([TargetID: [String]].self, forKey: .args) ?? [:]
        envs = try container
            .decodeIfPresent([TargetID: [String: String]].self, forKey: .envs)
            ?? [:]
        extraFiles = try container
            .decodeIfPresent(Set<FilePath>.self, forKey: .extraFiles) ?? []
        schemeAutogenerationMode = try container
            .decodeIfPresent(
                SchemeAutogenerationMode.self,
                forKey: .schemeAutogenerationMode
            ) ?? .all
        forceBazelDependencies = try container
            .decodeIfPresent(Bool.self, forKey: .forceBazelDependencies) ?? true
        indexImport = try container
            .decode(String.self, forKey: .indexImport)
        preBuildScript = try container
            .decodeIfPresent(String.self, forKey: .preBuildScript)
        postBuildScript = try container
            .decodeIfPresent(String.self, forKey: .postBuildScript)
    }
}
