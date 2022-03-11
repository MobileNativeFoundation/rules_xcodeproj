import PathKit

struct FilePath: Hashable, Decodable {
    enum PathType: String, Decodable {
        case input
        case `internal`
    }

    let type: PathType
    let path: Path

    fileprivate init(type: PathType, path: Path) {
        self.type = type
        self.path = path
    }

    // MARK: Decodable

    enum CodingKeys: String, CodingKey {
        case type
        case path
    }

    init(from decoder: Decoder) throws {
        // A plain string is interpreted as a source file
        if let path = try? decoder.singleValueContainer().decode(Path.self) {
            type = .input
            self.path = path
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(Path.self, forKey: .path)
        type = try container.decodeIfPresent(PathType.self, forKey: .type)
            ?? .input
    }
}

extension FilePath {
    static func input(_ path: Path) -> FilePath {
        return FilePath(type: .input, path: path)
    }

    static func `internal`(_ path: Path) -> FilePath {
        return FilePath(type: .internal, path: path)
    }
}

// MARK: Operators

func +(lhs: FilePath, rhs: String) -> FilePath {
    return FilePath(type: lhs.type, path: lhs.path + rhs)
}
