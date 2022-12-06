import OrderedCollections

struct LinkerInputs: Equatable {
    let staticFrameworks: [FilePath]
    let dynamicFrameworks: [FilePath]
    var staticLibraries: OrderedSet<FilePath>
    var forceLoad: OrderedSet<FilePath>
    let linkopts: [String]

    init(
        staticFrameworks: [FilePath] = [],
        dynamicFrameworks: [FilePath] = [],
        staticLibraries: OrderedSet<FilePath> = [],
        forceLoad: OrderedSet<FilePath> = [],
        linkopts: [String] = []
    ) {
        self.staticFrameworks = staticFrameworks
        self.dynamicFrameworks = dynamicFrameworks
        self.staticLibraries = staticLibraries
        self.forceLoad = forceLoad
        self.linkopts = linkopts
    }
}

extension LinkerInputs {
    var nonGenerated: Set<FilePath> {
        return Set(staticFrameworks.filter { $0.type != .generated })
            .union(Set(dynamicFrameworks.filter { $0.type != .generated }))
            .union(Set(staticLibraries.filter { $0.type != .generated }))
            .union(Set(forceLoad.filter { $0.type != .generated }))
    }
}

// MARK: - Decodable

extension LinkerInputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case staticFrameworks
        case dynamicFrameworks
        case staticLibraries
        case forceLoad
        case linkopts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        staticFrameworks = try container.decodeFilePaths(.staticFrameworks)
        dynamicFrameworks = try container.decodeFilePaths(.dynamicFrameworks)
        staticLibraries = try container.decodeFilePaths(.staticLibraries)
        forceLoad = try container.decodeFilePaths(.forceLoad)
        linkopts = try container
            .decodeIfPresent([String].self, forKey: .linkopts) ?? []
    }
}

private extension KeyedDecodingContainer where K == LinkerInputs.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }

    func decodeFilePaths(_ key: K) throws -> OrderedSet<FilePath> {
        return try decodeIfPresent(OrderedSet<FilePath>.self, forKey: key) ?? []
    }
}
