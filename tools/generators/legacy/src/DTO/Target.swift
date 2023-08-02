import PathKit

struct Target: Equatable {
    var name: String
    var label: BazelLabel
    let configuration: String
    let xcodeConfigurations: Set<String>
    var compileTargets: [CompileTarget]
    let packageBinDir: Path
    var platform: Platform
    var product: Product
    let testHost: TargetID?
    var buildSettings: [String: BuildSetting]
    let cParams: FilePath?
    let cxxParams: FilePath?
    let swiftParams: FilePath?
    let cHasFortifySource: Bool
    let cxxHasFortifySource: Bool
    let hasModulemaps: Bool
    var inputs: Inputs
    var linkerInputs: LinkerInputs
    var linkParams: FilePath?
    let resourceBundleDependencies: Set<TargetID>
    let watchApplication: TargetID?
    let extensions: Set<TargetID>
    let appClips: Set<TargetID>
    var dependencies: Set<TargetID>
    var outputs: Outputs
    let isUnfocusedDependency: Bool
    var additionalSchemeTargets: Set<TargetID>
}

struct CompileTarget: Equatable {
    let id: TargetID
    let name: String
}

extension Target {
    var allDependencies: Set<TargetID> {
        return dependencies.union(resourceBundleDependencies)
    }
}

// MARK: - Decodable

extension Target: Decodable {
    enum CodingKeys: String, CodingKey {
        case name = "n"
        case label = "l"
        case configuration = "c"
        case xcodeConfigurations = "x"
        case compileTargets = "3"
        case packageBinDir = "1"
        case platform = "2"
        case product = "p"
        case testHost = "h"
        case buildSettings = "b"
        case cParams = "8"
        case cxxParams = "9"
        case swiftParams = "0"
        case cHasFortifySource = "f"
        case cxxHasFortifySource = "F"
        case hasModulemaps = "m"
        case inputs = "i"
        case linkerInputs = "5"
        case linkParams = "6"
        case resourceBundleDependencies = "r"
        case watchApplication = "w"
        case extensions = "e"
        case appClips = "a"
        case dependencies = "d"
        case outputs = "o"
        case isUnfocusedDependency = "u"
        case additionalSchemeTargets = "7"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        label = try container.decode(BazelLabel.self, forKey: .label)
        configuration = try container.decode(String.self, forKey: .configuration)
        xcodeConfigurations = try container.decodeIfPresent(
            Set<String>.self,
            forKey: .xcodeConfigurations
        ) ?? ["Debug"]
        compileTargets = try container
            .decodeIfPresent([CompileTarget].self, forKey: .compileTargets) ?? []
        packageBinDir = try container.decode(Path.self, forKey: .packageBinDir)
        platform = try container.decode(Platform.self, forKey: .platform)
        product = try container.decode(Product.self, forKey: .product)
        testHost = try container
            .decodeIfPresent(TargetID.self, forKey: .testHost)
        buildSettings = try container
            .decodeIfPresent(
                [String: BuildSetting].self,
                forKey: .buildSettings
            ) ?? [:]
        cParams = try container
            .decodeIfPresent(FilePath.self, forKey: .cParams)
        cxxParams = try container
            .decodeIfPresent(FilePath.self, forKey: .cxxParams)
        swiftParams = try container
            .decodeIfPresent(FilePath.self, forKey: .swiftParams)
        cHasFortifySource = try container
            .decodeIfPresent(Bool.self, forKey: .cHasFortifySource) ?? false
        cxxHasFortifySource = try container
            .decodeIfPresent(Bool.self, forKey: .cxxHasFortifySource) ?? false
        hasModulemaps = try container
            .decodeIfPresent(Bool.self, forKey: .hasModulemaps) ?? false
        inputs = try container
            .decodeIfPresent(Inputs.self, forKey: .inputs) ?? .init()
        linkerInputs = try container
            .decodeIfPresent(LinkerInputs.self, forKey: .linkerInputs) ??
            .init()
        linkParams = try container
            .decodeIfPresent(FilePath.self, forKey: .linkParams)
        resourceBundleDependencies = try container
            .decodeTargetIDs(.resourceBundleDependencies)
        watchApplication = try container
            .decodeIfPresent(TargetID.self, forKey: .watchApplication)
        extensions = try container.decodeTargetIDs(.extensions)
        appClips = try container.decodeTargetIDs(.appClips)
        dependencies = try container.decodeTargetIDs(.dependencies)
        outputs = try container
            .decodeIfPresent(Outputs.self, forKey: .outputs) ?? .init()
        isUnfocusedDependency = try container
            .decodeIfPresent(Bool.self, forKey: .isUnfocusedDependency) ?? false
        additionalSchemeTargets = try container
            .decodeTargetIDs(.additionalSchemeTargets)
    }
}

extension CompileTarget: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "i"
        case name = "n"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(TargetID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }
}

private extension KeyedDecodingContainer where K == Target.CodingKeys {
    func decodeTargetIDs(_ key: K) throws -> Set<TargetID> {
        return try decodeIfPresent(Set<TargetID>.self, forKey: key) ?? []
    }
}
