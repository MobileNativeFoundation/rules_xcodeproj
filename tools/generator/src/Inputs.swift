struct Inputs: Equatable {
    var srcs: [FilePath]
    var nonArcSrcs: [FilePath]
    var hdrs: Set<FilePath>
    var resources: Set<FilePath>
    var containsGeneratedFiles: Bool

    init(
        srcs: [FilePath] = [],
        nonArcSrcs: [FilePath] = [],
        hdrs: Set<FilePath> = [],
        resources: Set<FilePath> = [],
        containsGeneratedFiles: Bool = false
    ) {
        self.srcs = srcs
        self.nonArcSrcs = nonArcSrcs
        self.hdrs = hdrs
        self.resources = resources
        self.containsGeneratedFiles = containsGeneratedFiles
    }
}

extension Inputs {
    mutating func merge(_ other: Inputs) {
        srcs = other.srcs
        nonArcSrcs = other.nonArcSrcs
        hdrs = other.hdrs
        resources.formUnion(other.resources)
        containsGeneratedFiles = containsGeneratedFiles
            || other.containsGeneratedFiles
    }

    func merging(_ other: Inputs) -> Inputs {
        var inputs = self
        inputs.merge(other)
        return inputs
    }
}

extension Inputs {
    var all: Set<FilePath> {
        return Set(srcs)
            .union(Set(nonArcSrcs))
            .union(Set(hdrs))
            .union(resources)
    }
}

// MARK: - Decodable

extension Inputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case srcs
        case nonArcSrcs
        case hdrs
        case resources
        case containsGeneratedFiles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        srcs = try container.decodeFilePaths(.srcs)
        nonArcSrcs = try container.decodeFilePaths(.nonArcSrcs)
        hdrs = try container.decodeFilePaths(.hdrs)
        resources = try container.decodeFilePaths(.resources)
        containsGeneratedFiles = try container.decodeIfPresent(
            Bool.self,
            forKey: .containsGeneratedFiles
        ) ?? false
    }
}

private extension KeyedDecodingContainer where K == Inputs.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }

    func decodeFilePaths(_ key: K) throws -> Set<FilePath> {
        return try decodeIfPresent(Set<FilePath>.self, forKey: key) ?? []
    }
}
