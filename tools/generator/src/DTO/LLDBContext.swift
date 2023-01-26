import PathKit

struct LLDBContext: Equatable {
    let frameworkSearchPaths: [String]
    let swiftmodules: [String]
    let clangOpts: [[String]]

    init(
        frameworkSearchPaths: [String] = [],
        swiftmodules: [String] = [],
        clangOpts: [[String]] = []
    ) {
        self.frameworkSearchPaths = frameworkSearchPaths
        self.swiftmodules = swiftmodules
        self.clangOpts = clangOpts
    }
}

// MARK: - Decodable

extension LLDBContext: Decodable {
    enum CodingKeys: String, CodingKey {
        case frameworkSearchPaths = "f"
        case swiftmodules = "s"
        case clangOpts = "c"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        frameworkSearchPaths = try container
            .decodeIfPresent([String].self, forKey: .frameworkSearchPaths) ?? []
        swiftmodules = try container
            .decodeIfPresent([String].self, forKey: .swiftmodules) ?? []
        clangOpts = try container
            .decodeIfPresent([[String]].self, forKey: .clangOpts) ?? []
    }
}
