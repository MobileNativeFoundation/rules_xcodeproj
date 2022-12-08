struct Outputs: Equatable {
    struct Swift: Equatable {
        let module: FilePath
        let generatedHeader: FilePath?

        init(
            module: FilePath,
            generatedHeader: FilePath? = nil
        ) {
            self.module = module
            self.generatedHeader = generatedHeader
        }
    }

    var swift: Swift?
    let hasProductOutput: Bool

    init(hasProductOutput: Bool = false, swift: Swift? = nil) {
        self.hasProductOutput = hasProductOutput
        self.swift = swift
    }
}

extension Outputs {
    var hasOutputs: Bool {
        return hasSwiftOutputs || hasProductOutput
    }

    var hasSwiftOutputs: Bool {
        return swift != nil
    }

    mutating func merge(_ other: Outputs) {
        swift = other.swift
    }

    func merging(_ other: Outputs) -> Outputs {
        var types = self
        types.merge(other)
        return types
    }
}

// MARK: - Decodable

extension Outputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case hasProductOutput = "p"
        case swift = "s"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hasProductOutput = try container
            .decodeIfPresent(Bool.self, forKey: .hasProductOutput) ?? false
        swift = try container.decodeIfPresent(Swift.self, forKey: .swift)
    }
}

extension Outputs.Swift: Decodable {
    enum CodingKeys: String, CodingKey {
        case module = "m"
        case generatedHeader = "h"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        module = try container.decode(FilePath.self, forKey: .module)
        generatedHeader = try container.decodeIfPresent(
            FilePath.self,
            forKey: .generatedHeader
        )
    }
}

private extension KeyedDecodingContainer where K == Outputs.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }
}
