import OrderedCollections

struct LinkerInputs: Equatable {
    let dynamicFrameworks: [FilePath]
    let linkopts: [String]

    init(
        dynamicFrameworks: [FilePath] = [],
        linkopts: [String] = []
    ) {
        self.dynamicFrameworks = dynamicFrameworks
        self.linkopts = linkopts
    }
}

// MARK: - Decodable

extension LinkerInputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case dynamicFrameworks
        case linkopts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        dynamicFrameworks = try container.decodeFilePaths(.dynamicFrameworks)
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
