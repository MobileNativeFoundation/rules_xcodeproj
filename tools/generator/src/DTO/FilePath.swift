import PathKit

struct FilePath: Hashable, Decodable {
    enum PathType: String, Decodable {
        case project = "p"
        case external = "e"
        case generated = "g"
        case `internal` = "i"
    }

    let type: PathType
    var path: Path
    var isFolder: Bool
    let includeInNavigator: Bool
    var forceGroupCreation: Bool

    fileprivate init(
        type: PathType,
        path: Path,
        isFolder: Bool,
        includeInNavigator: Bool,
        forceGroupCreation: Bool
    ) {
        self.type = type
        self.path = path
        self.isFolder = isFolder
        self.includeInNavigator = includeInNavigator
        self.forceGroupCreation = forceGroupCreation
    }

    // MARK: Decodable

    enum CodingKeys: String, CodingKey {
        case path = "_"
        case type = "t"
        case isFolder = "f"
        case includeInNavigator = "i"
        case forceGroupCreation = "g"
    }

    init(from decoder: Decoder) throws {
        // A plain string is interpreted as a source file
        if let path = try? decoder.singleValueContainer().decode(Path.self) {
            type = .project
            self.path = path
            isFolder = false
            includeInNavigator = true
            forceGroupCreation = false
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(Path.self, forKey: .path)
        type = try container.decodeIfPresent(PathType.self, forKey: .type)
            ?? .project
        isFolder = try container.decodeIfPresent(Bool.self, forKey: .isFolder)
            ?? false
        includeInNavigator = try container
            .decodeIfPresent(Bool.self, forKey: .includeInNavigator) ?? true
        forceGroupCreation = try container
            .decodeIfPresent(Bool.self, forKey: .forceGroupCreation) ?? false
    }
}

extension FilePath {
    static func project(
        _ path: Path,
        isFolder: Bool = false,
        includeInNavigator: Bool = true,
        forceGroupCreation: Bool = false
    ) -> FilePath {
        return FilePath(
            type: .project,
            path: path,
            isFolder: isFolder,
            includeInNavigator: includeInNavigator,
            forceGroupCreation: forceGroupCreation
        )
    }

    static func external(
        _ path: Path,
        isFolder: Bool = false,
        includeInNavigator: Bool = true,
        forceGroupCreation: Bool = false
    ) -> FilePath {
        return FilePath(
            type: .external,
            path: path,
            isFolder: isFolder,
            includeInNavigator: includeInNavigator,
            forceGroupCreation: forceGroupCreation
        )
    }

    static func generated(
        _ path: Path,
        isFolder: Bool = false,
        includeInNavigator: Bool = true,
        forceGroupCreation: Bool = false
    ) -> FilePath {
        return FilePath(
            type: .generated,
            path: path,
            isFolder: isFolder,
            includeInNavigator: includeInNavigator,
            forceGroupCreation: forceGroupCreation
        )
    }

    static func `internal`(
        _ path: Path,
        isFolder: Bool = false,
        includeInNavigator: Bool = true,
        forceGroupCreation: Bool = false
    ) -> FilePath {
        return FilePath(
            type: .internal,
            path: path,
            isFolder: isFolder,
            includeInNavigator: includeInNavigator,
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
            includeInNavigator: includeInNavigator,
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
        case .internal: return 3
        }
    }
}

// MARK: Operators

func + (lhs: FilePath, rhs: String) -> FilePath {
    return FilePath(
        type: lhs.type,
        path: lhs.path + rhs,
        isFolder: false,
        includeInNavigator: lhs.includeInNavigator,
        forceGroupCreation: lhs.forceGroupCreation
    )
}
