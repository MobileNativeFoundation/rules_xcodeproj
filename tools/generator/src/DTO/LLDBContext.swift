import PathKit

struct LLDBContext: Equatable {
    let frameworkSearchPaths: [String]
    let swiftmodules: [String]
    let clang: String

    init(
        frameworkSearchPaths: [String] = [],
        swiftmodules: [String] = [],
        clang: String = ""
    ) {
        self.frameworkSearchPaths = frameworkSearchPaths
        self.swiftmodules = swiftmodules
        self.clang = clang
    }
}

// MARK: - Decodable

extension LLDBContext: Decodable {
    enum CodingKeys: String, CodingKey {
        case frameworkSearchPaths = "f"
        case swiftmodules = "s"
        case clang = "c"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        frameworkSearchPaths = try container
            .decodeIfPresent([String].self, forKey: .frameworkSearchPaths) ?? []
        swiftmodules = try container
            .decodeIfPresent([String].self, forKey: .swiftmodules) ?? []
        clang = try container.decodeIfPresent(String.self, forKey: .clang) ?? ""
    }
}
