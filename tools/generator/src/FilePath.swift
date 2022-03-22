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

    fileprivate init(type: PathType, path: Path) {
        self.type = type
        self.path = path
    }

    // MARK: Decodable

    enum CodingKeys: String, CodingKey {
        case type = "t"
        case path = "_"
    }

    init(from decoder: Decoder) throws {
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
    static func project(_ path: Path) -> FilePath {
        return FilePath(type: .project, path: path)
    }

    static func external(_ path: Path) -> FilePath {
        return FilePath(type: .external, path: path)
    }

    static func generated(_ path: Path) -> FilePath {
        return FilePath(type: .generated, path: path)
    }

    static func `internal`(_ path: Path) -> FilePath {
        return FilePath(type: .internal, path: path)
    }
}

// MARK: Operators

func +(lhs: FilePath, rhs: String) -> FilePath {
    return FilePath(type: lhs.type, path: lhs.path + rhs)
}
