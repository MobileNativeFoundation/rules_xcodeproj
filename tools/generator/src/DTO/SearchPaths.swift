struct SearchPaths: Equatable {
    let frameworkIncludes: [FilePath]
    var quoteIncludes: [FilePath]
    var includes: [FilePath]
    var systemIncludes: [FilePath]

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

extension SearchPaths {
    var hasIncludes: Bool {
        return !frameworkIncludes.isEmpty
            || !quoteIncludes.isEmpty
            || !includes.isEmpty
            || !systemIncludes.isEmpty
    }

    mutating func merge(_ other: SearchPaths) {
        quoteIncludes = other.quoteIncludes
        includes = other.includes
        systemIncludes = other.systemIncludes
    }

    func merging(_ other: SearchPaths) -> SearchPaths {
        var searchPaths = self
        searchPaths.merge(other)
        return searchPaths
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
