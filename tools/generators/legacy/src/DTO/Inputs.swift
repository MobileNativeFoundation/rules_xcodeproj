struct Inputs: Equatable {
    var srcs: [FilePath]
    var nonArcSrcs: [FilePath]
    let hdrs: Set<FilePath>
    var resources: Set<FilePath>

    init(
        srcs: [FilePath] = [],
        nonArcSrcs: [FilePath] = [],
        hdrs: Set<FilePath> = [],
        resources: Set<FilePath> = []
    ) {
        self.srcs = srcs
        self.nonArcSrcs = nonArcSrcs
        self.hdrs = hdrs
        self.resources = resources
    }
}

extension Inputs {
    var all: Set<FilePath> { nonResources.union(resources) }

    var nonResources: Set<FilePath> {
        return Set(srcs)
            .union(Set(nonArcSrcs))
            .union(Set(hdrs))
    }
}

// MARK: - Decodable

extension Inputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case srcs = "s"
        case nonArcSrcs = "n"
        case hdrs = "h"
        case resources = "r"
        case folderResources = "f"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        srcs = try container.decodeFilePaths(.srcs)
        nonArcSrcs = try container.decodeFilePaths(.nonArcSrcs)
        hdrs = try container.decodeFilePaths(.hdrs)
        resources = try Set(
            container.decodeFilePaths(.resources) +
            container.decodeFolderFilePaths(.folderResources)
        )
    }
}

private extension KeyedDecodingContainer where K == Inputs.CodingKeys {
    func decodeFilePaths(_ key: K) throws -> [FilePath] {
        return try decodeIfPresent([FilePath].self, forKey: key) ?? []
    }

    func decodeFilePaths(_ key: K) throws -> Set<FilePath> {
        return try decodeIfPresent(Set<FilePath>.self, forKey: key) ?? []
    }

    func decodeFolderFilePaths(_ key: K) throws -> [FilePath] {
        var folders = try decodeIfPresent([FilePath].self, forKey: key) ?? []
        for i in folders.indices {
            folders[i].isFolder = true
        }
        return folders
    }
}
