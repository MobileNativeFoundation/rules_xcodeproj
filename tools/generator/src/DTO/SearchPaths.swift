struct SearchPaths: Equatable {
    let hasIncludes: Bool

    init(hasIncludes: Bool = false) {
        self.hasIncludes = hasIncludes
    }
}

// MARK: - Decodable

extension SearchPaths: Decodable {
    enum CodingKeys: String, CodingKey {
        case hasIncludes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hasIncludes = try container.decode(Bool.self, forKey: .hasIncludes)
    }
}
