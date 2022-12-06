import PathKit

struct LLDBContext: Equatable {
    struct Clang: Equatable {
        let quoteIncludes: [FilePath]
        let includes: [FilePath]
        let systemIncludes: [FilePath]
        let modulemaps: [FilePath]
        let opts: [String]

        init(
            quoteIncludes: [FilePath] = [],
            includes: [FilePath] = [],
            systemIncludes: [FilePath] = [],
            modulemaps: [FilePath] = [],
            opts: [String] = []
        ) {
            self.quoteIncludes = quoteIncludes
            self.includes = includes
            self.systemIncludes = systemIncludes
            self.modulemaps = modulemaps
            self.opts = opts
        }
    }

    let frameworkSearchPaths: [FilePath]
    let swiftmodules: [FilePath]
    let clang: [Clang]

    init(
        frameworkSearchPaths: [FilePath] = [],
        swiftmodules: [FilePath] = [],
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
            .decodeFilePaths(.frameworkSearchPaths)
        swiftmodules = try container.decodeFilePaths(.swiftmodules)
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

        quoteIncludes = try container.decodeFilePaths(.quoteIncludes)
        includes = try container.decodeFilePaths(.includes)
        systemIncludes = try container.decodeFilePaths(.systemIncludes)
        modulemaps = try container.decodeFilePaths(.modulemaps)
        opts = try container.decodeIfPresent([String].self, forKey: .opts) ?? []
    }
}

private extension KeyedDecodingContainer where K == LLDBContext.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}

private extension KeyedDecodingContainer where K == LLDBContext.Clang.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}
