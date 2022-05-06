struct Outputs: Equatable {
    struct Swift: Equatable {
        let module: FilePath
        let doc: FilePath
        let sourceInfo: FilePath
        let interface: FilePath?
        let generatedHeader: FilePath?

        init(
            module: FilePath,
            doc: FilePath,
            sourceInfo: FilePath,
            interface: FilePath? = nil,
            generatedHeader: FilePath? = nil
        ) {
            self.module = module
            self.doc = doc
            self.sourceInfo = sourceInfo
            self.interface = interface
            self.generatedHeader = generatedHeader
        }
    }

    let product: FilePath?
    var swift: Swift?

    init(
        product: FilePath? = nil,
        swift: Swift? = nil
    ) {
        self.product = product
        self.swift = swift
    }
}

extension Outputs {
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
        case product = "p"
        case swift = "s"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        product = try container.decodeIfPresent(FilePath.self, forKey: .product)
        swift = try container.decodeIfPresent(Swift.self, forKey: .swift)
    }
}

extension Outputs.Swift: Decodable {
    enum CodingKeys: String, CodingKey {
        case module = "m"
        case doc = "d"
        case sourceinfo = "s"
        case interface = "i"
        case generatedHeader = "h"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        module = try container.decode(FilePath.self, forKey: .module)
        doc = try container.decode(FilePath.self, forKey: .doc)
        sourceInfo = try container.decode(FilePath.self, forKey: .sourceinfo)
        interface = try container.decodeIfPresent(
            FilePath.self,
            forKey: .interface
        )
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
