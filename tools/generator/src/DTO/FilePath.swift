import PathKit

struct FilePath: Hashable, Decodable {
    enum PathType: String, Decodable {
        case project = "p"
        case external = "e"
        case generated = "g"
    }

    let type: PathType
    var path: Path
    var isFolder: Bool
    var forceGroupCreation: Bool

    fileprivate init(
        type: PathType,
        path: Path,
        isFolder: Bool,
        forceGroupCreation: Bool
    ) {
        self.type = type
        self.path = path
        self.isFolder = isFolder
        self.forceGroupCreation = forceGroupCreation
    }

    // MARK: Decodable

    enum CodingKeys: String, CodingKey {
        case path = "_"
        case type = "t"
    }

    init(from decoder: Decoder) throws {
        isFolder = false
        forceGroupCreation = false

        // A plain string is interpreted as a source file
        if let path = try? decoder.singleValueContainer().decode(Path.self) {
            type = .project
            self.path = path
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(Path.self, forKey: .path)
        type = try container.decodeIfPresent(PathType.self, forKey: .type)
            ?? .project
    }
}

extension FilePath {
    static func project(
        _ path: Path,
        isFolder: Bool = false,
        forceGroupCreation: Bool = false
    ) -> FilePath {
        return FilePath(
            type: .project,
            path: path,
            isFolder: isFolder,
            forceGroupCreation: forceGroupCreation
        )
    }

    static func external(
        _ path: Path,
        isFolder: Bool = false,
        forceGroupCreation: Bool = false
    ) -> FilePath {
        return FilePath(
            type: .external,
            path: path,
            isFolder: isFolder,
            forceGroupCreation: forceGroupCreation
        )
    }

    static func generated(
        _ path: Path,
        isFolder: Bool = false,
        forceGroupCreation: Bool = false
    ) -> FilePath {
        return FilePath(
            type: .generated,
            path: path,
            isFolder: isFolder,
            forceGroupCreation: forceGroupCreation
        )
    }
}

extension FilePath {
    func parent() -> FilePath {
        return FilePath(
            type: type,
            path: path.parent().normalize(),
            isFolder: false,
            forceGroupCreation: forceGroupCreation
        )
    }
}

// MARK: Comparable

extension FilePath: Comparable {
    static func < (lhs: FilePath, rhs: FilePath) -> Bool {
        guard lhs.path == rhs.path else {
            return lhs.path < rhs.path
        }
        guard lhs.type == rhs.type else {
            return lhs.type < rhs.type
        }
        return lhs.isFolder
    }
}

extension FilePath.PathType: Comparable {
    static func < (lhs: FilePath.PathType, rhs: FilePath.PathType) -> Bool {
        return lhs.sortKey < rhs.sortKey
    }

    private var sortKey: Int {
        switch self {
        case .project: return 0
        case .external: return 1
        case .generated: return 2
        }
    }
}

// MARK: Operators

func + (lhs: FilePath, rhs: String) -> FilePath {
    let path: Path
    if rhs.isEmpty {
        path = lhs.path
    } else if lhs.path.string.isEmpty || lhs.path.string == "." {
        path = Path(rhs)
    } else {
        path = Path("\(lhs.path.string)/\(rhs)")
    }

    return FilePath(
        type: lhs.type,
        path: path,
        isFolder: false,
        forceGroupCreation: lhs.forceGroupCreation
    )
}
