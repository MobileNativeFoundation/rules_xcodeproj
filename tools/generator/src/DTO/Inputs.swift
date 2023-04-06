struct Inputs: Equatable {
    var srcs: [FilePath]
    var nonArcSrcs: [FilePath]
    let hdrs: Set<FilePath>
    var pch: FilePath?
    var resources: Set<FilePath>
    var entitlements: FilePath?

    init(
        srcs: [FilePath] = [],
        nonArcSrcs: [FilePath] = [],
        hdrs: Set<FilePath> = [],
        pch: FilePath? = nil,
        resources: Set<FilePath> = [],
        entitlements: FilePath? = nil
    ) {
        self.srcs = srcs
        self.nonArcSrcs = nonArcSrcs
        self.hdrs = hdrs
        self.pch = pch
        self.resources = resources
        self.entitlements = entitlements
    }
}

extension Inputs {
    var all: Set<FilePath> { nonResources.union(resources) }

    var nonResources: Set<FilePath> {
        return Set(srcs)
            .union(Set(nonArcSrcs))
            .union(Set(hdrs))
            .union(pchSet)
            .union(entitlementsSet)
    }

    private var pchSet: Set<FilePath> {
        guard let pch = pch else {
            return []
        }
        return [pch]
    }

    private var entitlementsSet: Set<FilePath> {
        guard let entitlements = entitlements else {
            return []
        }
        return [entitlements]
    }
}

// MARK: - Decodable

extension Inputs: Decodable {
    enum CodingKeys: String, CodingKey {
        case srcs = "s"
        case nonArcSrcs = "n"
        case hdrs = "h"
        case pch = "p"
        case resources = "r"
        case folderResources = "f"
        case entitlements = "e"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        srcs = try container.decodeFilePaths(.srcs)
        nonArcSrcs = try container.decodeFilePaths(.nonArcSrcs)
        hdrs = try container.decodeFilePaths(.hdrs)
        pch = try container.decodeIfPresent(FilePath.self, forKey: .pch)
        resources = try Set(
            container.decodeFilePaths(.resources) +
            container.decodeFolderFilePaths(.folderResources)
        )
        entitlements = try container
            .decodeIfPresent(FilePath.self, forKey: .entitlements)
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
            folders[i].forceGroupCreation = true
        }
        return folders
    }
}
