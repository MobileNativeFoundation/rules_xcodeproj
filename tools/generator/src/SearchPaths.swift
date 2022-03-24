struct SearchPaths: Equatable {
    let quoteIncludes: [FilePath]
    let includes: [FilePath]

    init(
        quoteIncludes: [FilePath] = [],
        includes: [FilePath] = []
    ) {
        self.quoteIncludes = quoteIncludes
        self.includes = includes
    }
}

// MARK: - Decodable

extension SearchPaths: Decodable {
    enum CodingKeys: String, CodingKey {
        case quoteIncludes
        case includes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        quoteIncludes = try container.decodeFilePaths(.quoteIncludes)
        includes = try container.decodeFilePaths(.includes)
    }
}

private extension KeyedDecodingContainer where K == SearchPaths.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}
