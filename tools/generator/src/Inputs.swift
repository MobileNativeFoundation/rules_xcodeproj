struct Inputs: Equatable {
    let srcs: Set<FilePath>
    let nonArcSrcs: Set<FilePath>

    init(srcs: Set<FilePath> = [], nonArcSrcs: Set<FilePath> = []) {
        self.srcs = srcs
        self.nonArcSrcs = nonArcSrcs
    }
}

extension Inputs {
    var all: Set<FilePath> {
        return srcs
            .union(nonArcSrcs)
    }
}

// MARK: - Decodable

extension Inputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case srcs
        case nonArcSrcs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        srcs = try container.decodeFilePaths(.srcs)
        nonArcSrcs = try container.decodeFilePaths(.nonArcSrcs)
    }
}

private extension KeyedDecodingContainer where K == Inputs.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> Set<FilePath> {
        return try decodeIfPresent(Set<FilePath>.self, forKey: key) ?? []
    }
}
