import PathKit

struct Target: Equatable {
    var name: String
    var label: BazelLabel
    let configuration: String
    var compileTarget: CompileTarget? = nil
    let packageBinDir: Path
    var platform: Platform
    var product: Product
    var isTestonly: Bool
    var isSwift: Bool
    let testHost: TargetID?
    var buildSettings: [String: BuildSetting]
    var searchPaths: SearchPaths
    var modulemaps: [FilePath]
    var swiftmodules: [FilePath]
    var inputs: Inputs
    var linkerInputs: LinkerInputs
    var infoPlist: FilePath?
    var entitlements: FilePath?
    let resourceBundleDependencies: Set<TargetID>
    let watchApplication: TargetID?
    let extensions: Set<TargetID>
    let appClips: Set<TargetID>
    var dependencies: Set<TargetID>
    var outputs: Outputs
    let lldbContext: LLDBContext?
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
        case name
        case label
        case configuration
        case packageBinDir
        case platform
        case product
        case isTestonly
        case isSwift
        case testHost
        case buildSettings
        case searchPaths
        case modulemaps
        case swiftmodules
        case inputs
        case linkerInputs
        case infoPlist
        case entitlements
        case resourceBundleDependencies
        case watchApplication
        case extensions
        case appClips
        case dependencies
        case outputs
        case lldbContext
        case isUnfocusedDependency
        case additionalSchemeTargets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        label = try container.decode(BazelLabel.self, forKey: .label)
        configuration = try container.decode(String.self, forKey: .configuration)
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
        searchPaths = try container
            .decodeIfPresent(SearchPaths.self, forKey: .searchPaths) ?? .init()
        modulemaps = try container.decodeFilePaths(.modulemaps)
        swiftmodules = try container.decodeFilePaths(.swiftmodules)
        inputs = try container
            .decodeIfPresent(Inputs.self, forKey: .inputs) ?? .init()
        linkerInputs = try container
            .decodeIfPresent(LinkerInputs.self, forKey: .linkerInputs) ??
            .init()
        infoPlist = try container
            .decodeIfPresent(FilePath.self, forKey: .infoPlist)
        entitlements = try container
            .decodeIfPresent(FilePath.self, forKey: .entitlements)
        resourceBundleDependencies = try container
            .decodeTargetIDs(.resourceBundleDependencies)
        watchApplication = try container
            .decodeIfPresent(TargetID.self, forKey: .watchApplication)
        extensions = try container.decodeTargetIDs(.extensions)
        appClips = try container.decodeTargetIDs(.appClips)
        dependencies = try container.decodeTargetIDs(.dependencies)
        outputs = try container
            .decodeIfPresent(Outputs.self, forKey: .outputs) ?? .init()
        lldbContext = try container
            .decodeIfPresent(LLDBContext.self, forKey: .lldbContext)
        isUnfocusedDependency = try container
            .decodeIfPresent(Bool.self, forKey: .isUnfocusedDependency) ?? false
        additionalSchemeTargets = try container
            .decodeTargetIDs(.additionalSchemeTargets)
    }
}

private extension KeyedDecodingContainer where K == Target.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }

    func decodeFilePaths(_ key: K) throws -> Set<FilePath> {
        return try decodeIfPresent(Set<FilePath>.self, forKey: key) ?? []
    }

    func decodeTargetIDs(_ key: K) throws -> Set<TargetID> {
        return try decodeIfPresent(Set<TargetID>.self, forKey: key) ?? []
    }
}
