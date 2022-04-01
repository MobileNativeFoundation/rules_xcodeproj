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

    fileprivate init(type: PathType, path: Path, isFolder: Bool) {
        self.type = type
        self.path = path
        self.isFolder = isFolder
    }

    // MARK: Decodable

    enum CodingKeys: String, CodingKey {
        case path = "_"
        case type = "t"
        case isFolder = "f"
    }

    init(from decoder: Decoder) throws {
        // A plain string is interpreted as a source file
        if let path = try? decoder.singleValueContainer().decode(Path.self) {
            type = .project
            self.path = path
            isFolder = false
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(Path.self, forKey: .path)
        type = try container.decodeIfPresent(PathType.self, forKey: .type)
            ?? .project
        isFolder = try container.decodeIfPresent(Bool.self, forKey: .isFolder)
            ?? false
    }
}

extension FilePath {
    static func project(_ path: Path, isFolder: Bool = false) -> FilePath {
        return FilePath(type: .project, path: path, isFolder: isFolder)
    }

    static func external(_ path: Path, isFolder: Bool = false) -> FilePath {
        return FilePath(type: .external, path: path, isFolder: isFolder)
    }

    static func generated(_ path: Path, isFolder: Bool = false) -> FilePath {
        return FilePath(type: .generated, path: path, isFolder: isFolder)
    }

    static func `internal`(_ path: Path, isFolder: Bool = false) -> FilePath {
        return FilePath(type: .internal, path: path, isFolder: isFolder)
    }
}

// MARK: Operators

func +(lhs: FilePath, rhs: String) -> FilePath {
    return FilePath(type: lhs.type, path: lhs.path + rhs, isFolder: false)
}
