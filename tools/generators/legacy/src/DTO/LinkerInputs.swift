import OrderedCollections

struct LinkerInputs: Equatable {
    let dynamicFrameworks: [FilePath]

    init(
        dynamicFrameworks: [FilePath] = []
    ) {
        self.dynamicFrameworks = dynamicFrameworks
    }
}

// MARK: - Decodable

extension LinkerInputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case dynamicFrameworks = "d"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        dynamicFrameworks = try container.decodeFilePaths(.dynamicFrameworks)
    }
}

private extension KeyedDecodingContainer where K == LinkerInputs.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}
