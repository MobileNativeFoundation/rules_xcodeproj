struct XCCurrentVersion: Equatable {
    let container: FilePath
    let version: String
}

// MARK: - Decodable

extension XCCurrentVersion: Decodable {
    enum CodingKeys: String, CodingKey {
        case container = "c"
        case version = "v"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.container = try container.decode(FilePath.self, forKey: .container)
        version = try container.decode(String.self, forKey: .version)
    }
}
