import PathKit

struct LLDBContext: Equatable {
    struct Clang: Equatable {
        let quoteIncludes: [String]
        let includes: [String]
        let systemIncludes: [String]
        let modulemaps: [String]
        let opts: [String]

        init(
            quoteIncludes: [String] = [],
            includes: [String] = [],
            systemIncludes: [String] = [],
            modulemaps: [String] = [],
            opts: [String] = []
        ) {
            self.quoteIncludes = quoteIncludes
            self.includes = includes
            self.systemIncludes = systemIncludes
            self.modulemaps = modulemaps
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
        case quoteIncludes = "q"
        case includes = "i"
        case systemIncludes = "s"
        case modulemaps = "m"
        case opts = "o"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        quoteIncludes = try container
            .decodeIfPresent([String].self, forKey: .quoteIncludes) ?? []
        includes = try container
            .decodeIfPresent([String].self, forKey: .includes) ?? []
        systemIncludes = try container
            .decodeIfPresent([String].self, forKey: .systemIncludes) ?? []
        modulemaps = try container
            .decodeIfPresent([String].self, forKey: .modulemaps) ?? []
        opts = try container.decodeIfPresent([String].self, forKey: .opts) ?? []
    }
}
