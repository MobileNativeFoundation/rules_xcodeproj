struct SearchPaths: Equatable {
    let quoteHeaders: [FilePath]
    let includes: [FilePath]

    init(quoteHeaders: [FilePath] = [], includes: [FilePath] = []) {
        self.quoteHeaders = quoteHeaders
        self.includes = includes
    }
}

// MARK: - Decodable

extension SearchPaths: Decodable {
    enum CodingKeys: String, CodingKey {
        case quoteHeaders
        case includes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        quoteHeaders = try container.decodeFilePaths(.quoteHeaders)
        includes = try container.decodeFilePaths(.includes)
    }
}

private extension KeyedDecodingContainer where K == SearchPaths.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}
