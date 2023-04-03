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
    let productBasename: String?

    init(productBasename: String? = nil, swift: Swift? = nil) {
        self.productBasename = productBasename
        self.swift = swift
    }
}

extension Outputs {
    var hasOutputs: Bool {
        return hasSwiftOutputs || productBasename != nil
    }

    var hasSwiftOutputs: Bool {
        return swift != nil
    }
}

// MARK: - Decodable

extension Outputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case productBasename = "p"
        case swift = "s"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        productBasename = try container
            .decodeIfPresent(String.self, forKey: .productBasename)
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
