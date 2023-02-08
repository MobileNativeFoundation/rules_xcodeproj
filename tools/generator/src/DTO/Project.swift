struct Project: Equatable {
    struct Options: Equatable {
        let developmentRegion: String
        let indentWidth: UInt?
        let tabWidth: UInt?
        let usesTabs: Bool?

        init(
            developmentRegion: String = "en",
            indentWidth: UInt? = nil,
            tabWidth: UInt? = nil,
            usesTabs: Bool? = nil
        ) {
            self.developmentRegion = developmentRegion
            self.indentWidth = indentWidth
            self.tabWidth = tabWidth
            self.usesTabs = usesTabs
        }
    }

    let name: String
    let options: Options
    let bazel: String
    let bazelConfig: String
    let generatorLabel: BazelLabel
    let runnerLabel: BazelLabel
    let minimumXcodeVersion: SemanticVersion
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
        case options = "o"
        case bazel = "b"
        case bazelConfig = "B"
        case generatorLabel = "g"
        case runnerLabel = "R"
        case minimumXcodeVersion = "m"
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
        options = try container.decodeIfPresent(Options.self, forKey: .options)
            ?? Options()
        bazel = try container
            .decodeIfPresent(String.self, forKey: .bazel) ?? "bazel"
        bazelConfig = try container.decode(String.self, forKey: .bazelConfig)
        generatorLabel = try container
            .decode(BazelLabel.self, forKey: .generatorLabel)
        runnerLabel = try container
            .decode(BazelLabel.self, forKey: .runnerLabel)
        minimumXcodeVersion = try container
            .decode(SemanticVersion.self, forKey: .minimumXcodeVersion)
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

extension Project.Options: Decodable {
    enum CodingKeys: String, CodingKey {
        case developmentRegion = "d"
        case indentWidth = "i"
        case tabWidth = "t"
        case usesTabs = "u"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        developmentRegion = try container
            .decodeIfPresent(String.self, forKey: .developmentRegion) ?? "en"
        indentWidth = try container
            .decodeIfPresent(UInt.self, forKey: .indentWidth)
        tabWidth = try container.decodeIfPresent(UInt.self, forKey: .tabWidth)
        usesTabs = try container.decodeIfPresent(Bool.self, forKey: .usesTabs)
    }
}
