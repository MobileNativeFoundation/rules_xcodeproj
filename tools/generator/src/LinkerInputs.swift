import OrderedCollections

struct LinkerInputs: Equatable {
    var staticFrameworks: [FilePath]
    var dynamicFrameworks: [FilePath]
    var staticLibraries: OrderedSet<FilePath>

    init(
        staticFrameworks: [FilePath] = [],
        dynamicFrameworks: [FilePath] = [],
        staticLibraries: OrderedSet<FilePath> = []
    ) {
        self.staticFrameworks = staticFrameworks
        self.dynamicFrameworks = dynamicFrameworks
        self.staticLibraries = staticLibraries
    }
}

extension LinkerInputs {
    var nonGenerated: Set<FilePath> {
        return Set(staticFrameworks.filter { $0.type != .generated })
            .union(Set(dynamicFrameworks.filter { $0.type != .generated }))
            .union(Set(staticLibraries.filter { $0.type != .generated }))
    }

    var frameworks: [FilePath] {
        return staticFrameworks + dynamicFrameworks
    }

    var embeddable: [FilePath] {
        return dynamicFrameworks
    }
}

// MARK: - Decodable

extension LinkerInputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case staticFrameworks
        case dynamicFrameworks
        case staticLibraries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        staticFrameworks = try container.decodeFilePaths(.staticFrameworks)
        dynamicFrameworks = try container.decodeFilePaths(.dynamicFrameworks)
        staticLibraries = try container.decodeFilePaths(.staticLibraries)
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
