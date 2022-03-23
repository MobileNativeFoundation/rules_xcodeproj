struct SearchPaths: Equatable {
    let frameworkIncludes: [FilePath]
    let quoteIncludes: [FilePath]
    let includes: [FilePath]

    init(
        frameworkIncludes: [FilePath] = [],
        quoteIncludes: [FilePath] = [],
        includes: [FilePath] = []
    ) {
        self.frameworkIncludes = frameworkIncludes
        self.quoteIncludes = quoteIncludes
        self.includes = includes
    }
}

// MARK: - Decodable

extension SearchPaths: Decodable {
    enum CodingKeys: String, CodingKey {
        case frameworkIncludes
        case quoteIncludes
        case includes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        frameworkIncludes = try container.decodeFilePaths(.frameworkIncludes)
        quoteIncludes = try container.decodeFilePaths(.quoteIncludes)
        includes = try container.decodeFilePaths(.includes)
    }
}

private extension KeyedDecodingContainer where K == SearchPaths.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}
