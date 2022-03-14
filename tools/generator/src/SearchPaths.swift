struct SearchPaths: Equatable {
    let quoteHeaders: [FilePath]

    init(quoteHeaders: [FilePath] = []) {
        self.quoteHeaders = quoteHeaders
    }
}

// MARK: - Decodable

extension SearchPaths: Decodable {
    enum CodingKeys: String, CodingKey {
        case quoteHeaders
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        quoteHeaders = try container.decodeFilePaths(.quoteHeaders)
    }
}

private extension KeyedDecodingContainer where K == SearchPaths.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}
