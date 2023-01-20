import PathKit

struct LLDBContext: Equatable {
    struct Clang: Equatable {
        let opts: [String]

        init(
            opts: [String] = []
        ) {
            self.opts = opts
        }
    }

    let frameworkSearchPaths: [String]
    let swiftmodules: [String]
    let clang: [Clang]

    init(
        frameworkSearchPaths: [String] = [],
        swiftmodules: [String] = [],
        clang: [Clang] = []
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
        clang = try container
            .decodeIfPresent([Clang].self, forKey: .clang) ?? []
    }
}

extension LLDBContext.Clang: Decodable {
    enum CodingKeys: String, CodingKey {
        case opts = "o"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        opts = try container.decodeIfPresent([String].self, forKey: .opts) ?? []
    }
}
