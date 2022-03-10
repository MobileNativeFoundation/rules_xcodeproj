struct Inputs: Equatable {
    let srcs: Set<FilePath>
    let nonArcSrcs: Set<FilePath>
    let hdrs: Set<FilePath>

    init(
        srcs: Set<FilePath> = [],
        nonArcSrcs: Set<FilePath> = [],
        hdrs: Set<FilePath> = []
    ) {
        self.srcs = srcs
        self.nonArcSrcs = nonArcSrcs
        self.hdrs = hdrs
    }
}

extension Inputs {
    var all: Set<FilePath> {
        return srcs
            .union(nonArcSrcs)
            .union(hdrs)
    }
}

// MARK: - Decodable

extension Inputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case srcs
        case nonArcSrcs
        case hdrs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        srcs = try container.decodeFilePaths(.srcs)
        nonArcSrcs = try container.decodeFilePaths(.nonArcSrcs)
        hdrs = try container.decodeFilePaths(.hdrs)
    }
}

private extension KeyedDecodingContainer where K == Inputs.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> Set<FilePath> {
        return try decodeIfPresent(Set<FilePath>.self, forKey: key) ?? []
    }
}
