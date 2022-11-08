struct SearchPaths: Equatable {
    let hasIncludes: Bool
    let frameworkIncludes: [FilePath]

    init(hasIncludes: Bool = false, frameworkIncludes: [FilePath] = []) {
        self.hasIncludes = hasIncludes
        self.frameworkIncludes = frameworkIncludes
    }
}

// MARK: - Decodable

extension SearchPaths: Decodable {
    enum CodingKeys: String, CodingKey {
        case hasIncludes
        case frameworkIncludes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hasIncludes = try container.decode(Bool.self, forKey: .hasIncludes)
        frameworkIncludes = try container.decodeFilePaths(.frameworkIncludes)
    }
}

private extension KeyedDecodingContainer where K == SearchPaths.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}
