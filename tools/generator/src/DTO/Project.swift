struct Project: Equatable {
    struct Options: Equatable {
        let developmentRegion: String
        let indentWidth: UInt?
        let organizationName: String?
        let tabWidth: UInt?
        let usesTabs: Bool?

        init(
            developmentRegion: String = "en",
            indentWidth: UInt? = nil,
            organizationName: String? = nil,
            tabWidth: UInt? = nil,
            usesTabs: Bool? = nil
        ) {
            self.developmentRegion = developmentRegion
            self.indentWidth = indentWidth
            self.organizationName = organizationName
            self.tabWidth = tabWidth
            self.usesTabs = usesTabs
        }
    }

    let name: String
    let options: Options
    let bazelConfig: String
    let xcodeConfigurations: Set<String>
    let defaultXcodeConfiguration: String
    let runnerLabel: BazelLabel
    let minimumXcodeVersion: SemanticVersion
    var targets: [TargetID: Target] = [:]
    let targetHosts: [TargetID: [TargetID]]
    let args: [TargetID: [String]]
    let envs: [TargetID: [String: String]]
    let extraFiles: Set<FilePath>
    let schemeAutogenerationMode: SchemeAutogenerationMode
    var customXcodeSchemes: [XcodeScheme] = []
    let targetIdsFile: String
    let indexImport: String
    let preBuildScript: String?
    let postBuildScript: String?
}

extension Project: Decodable {
    enum CodingKeys: String, CodingKey {
        case name = "n"
        case options = "o"
        case bazelConfig = "B"
        case xcodeConfigurations = "x"
        case defaultXcodeConfiguration = "d"
        case runnerLabel = "R"
        case minimumXcodeVersion = "m"
        case targetHosts = "t"
        case envs = "E"
        case args = "a"
        case extraFiles = "e"
        case extraFolders = "F"
        case schemeAutogenerationMode = "s"
        case targetIdsFile = "T"
        case indexImport = "i"
        case preBuildScript = "p"
        case postBuildScript = "P"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        options = try container.decodeIfPresent(Options.self, forKey: .options)
            ?? Options()
        bazelConfig = try container.decode(String.self, forKey: .bazelConfig)
        xcodeConfigurations = try container
            .decodeIfPresent(Set<String>.self, forKey: .xcodeConfigurations) ??
            ["Debug"]
        defaultXcodeConfiguration = try container
            .decodeIfPresent(String.self, forKey: .defaultXcodeConfiguration) ??
            "Debug"
        runnerLabel = try container
            .decode(BazelLabel.self, forKey: .runnerLabel)
        minimumXcodeVersion = try container
            .decode(SemanticVersion.self, forKey: .minimumXcodeVersion)
        targetHosts = try container
            .decodeIfPresent([TargetID: [TargetID]].self, forKey: .targetHosts)
            ?? [:]
        args = try container
            .decodeIfPresent([TargetID: [String]].self, forKey: .args) ?? [:]
        envs = try container
            .decodeIfPresent([TargetID: [String: String]].self, forKey: .envs)
            ?? [:]
        extraFiles = try Set(
            container.decodeFilePaths(.extraFiles) +
            container.decodeFolderFilePaths(.extraFolders)
        )
        schemeAutogenerationMode = try container
            .decodeIfPresent(
                SchemeAutogenerationMode.self,
                forKey: .schemeAutogenerationMode
            ) ?? .all
        targetIdsFile = try container
            .decode(String.self, forKey: .targetIdsFile)
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
        case organizationName = "o"
        case tabWidth = "t"
        case usesTabs = "u"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        developmentRegion = try container
            .decodeIfPresent(String.self, forKey: .developmentRegion) ?? "en"
        indentWidth = try container
            .decodeIfPresent(UInt.self, forKey: .indentWidth)
        organizationName = try container
            .decodeIfPresent(String.self, forKey: .organizationName)
        tabWidth = try container.decodeIfPresent(UInt.self, forKey: .tabWidth)
        usesTabs = try container.decodeIfPresent(Bool.self, forKey: .usesTabs)
    }
}

private extension KeyedDecodingContainer where K == Project.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }

    func decodeFolderFilePaths(_ key: K) throws -> [FilePath] {
        var folders = try decodeIfPresent([FilePath].self, forKey: key) ?? []
        for i in folders.indices {
            folders[i].isFolder = true
            folders[i].forceGroupCreation = true
        }
        return folders
    }
}
