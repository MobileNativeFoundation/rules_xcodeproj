import PathKit

struct Target: Equatable {
    var name: String
    var label: BazelLabel
    let configuration: String
    let xcodeConfigurations: Set<String>
    var compileTarget: CompileTarget?
    let packageBinDir: Path
    var platform: Platform
    var product: Product
    var isTestonly: Bool
    var isSwift: Bool
    let testHost: TargetID?
    var buildSettings: [String: BuildSetting]
    let cFlags: [String]
    let cxxFlags: [String]
    let swiftFlags: [String]
    let hasModulemaps: Bool
    var inputs: Inputs
    var linkerInputs: LinkerInputs
    var linkParams: FilePath?
    var infoPlist: FilePath?
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
        case compileTarget = "3"
        case packageBinDir = "1"
        case platform = "2"
        case product = "p"
        case isTestonly = "t"
        case isSwift = "s"
        case testHost = "h"
        case buildSettings = "b"
        case cFlags = "8"
        case cxxFlags = "9"
        case swiftFlags = "0"
        case hasModulemaps = "m"
        case inputs = "i"
        case linkerInputs = "5"
        case linkParams = "6"
        case infoPlist = "4"
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
        xcodeConfigurations = try container
            .decodeIfPresent(Set<String>.self, forKey: .xcodeConfigurations) ??
            ["Debug"]
        compileTarget = try container
            .decodeIfPresent(CompileTarget.self, forKey: .compileTarget)
        packageBinDir = try container.decode(Path.self, forKey: .packageBinDir)
        platform = try container.decode(Platform.self, forKey: .platform)
        product = try container.decode(Product.self, forKey: .product)
        isTestonly = try container
            .decodeIfPresent(Bool.self, forKey: .isTestonly) ?? false
        isSwift = try container.decodeIfPresent(Bool.self, forKey: .isSwift) ??
            true
        testHost = try container
            .decodeIfPresent(TargetID.self, forKey: .testHost)
        buildSettings = try container
            .decodeIfPresent(
                [String: BuildSetting].self,
                forKey: .buildSettings
            ) ?? [:]
        cFlags = try container
            .decodeIfPresent([String].self, forKey: .cFlags) ?? []
        cxxFlags = try container
            .decodeIfPresent([String].self, forKey: .cxxFlags) ?? []
        swiftFlags = try container
            .decodeIfPresent([String].self, forKey: .swiftFlags) ?? []
        hasModulemaps = try container
            .decodeIfPresent(Bool.self, forKey: .hasModulemaps) ?? false
        inputs = try container
            .decodeIfPresent(Inputs.self, forKey: .inputs) ?? .init()
        linkerInputs = try container
            .decodeIfPresent(LinkerInputs.self, forKey: .linkerInputs) ??
            .init()
        linkParams = try container
            .decodeIfPresent(FilePath.self, forKey: .linkParams)
        infoPlist = try container
            .decodeIfPresent(FilePath.self, forKey: .infoPlist)
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
