struct SearchPaths: Equatable {
    let frameworkIncludes: [FilePath]
    let quoteIncludes: [FilePath]
    let includes: [FilePath]
    let systemIncludes: [FilePath]

    init(
        frameworkIncludes: [FilePath] = [],
        quoteIncludes: [FilePath] = [],
        includes: [FilePath] = [],
        systemIncludes: [FilePath] = []
    ) {
        self.frameworkIncludes = frameworkIncludes
        self.quoteIncludes = quoteIncludes
        self.includes = includes
        self.systemIncludes = systemIncludes
    }
}

// MARK: - Decodable

extension SearchPaths: Decodable {
    enum CodingKeys: String, CodingKey {
        case frameworkIncludes
        case quoteIncludes
        case includes
        case systemIncludes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        frameworkIncludes = try container.decodeFilePaths(.frameworkIncludes)
        quoteIncludes = try container.decodeFilePaths(.quoteIncludes)
        includes = try container.decodeFilePaths(.includes)
        systemIncludes = try container.decodeFilePaths(.systemIncludes)
    }
}

private extension KeyedDecodingContainer where K == SearchPaths.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}
