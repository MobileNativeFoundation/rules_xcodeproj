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

    init(swift: Swift? = nil) {
        self.swift = swift
    }
}

extension Outputs {
    var hasSwiftOutputs: Bool {
        return swift != nil
    }
}

// MARK: - Decodable

extension Outputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case swift = "s"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

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
