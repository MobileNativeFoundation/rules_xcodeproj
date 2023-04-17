import PathKit

struct FilePath: Hashable, Decodable {
    var path: Path
    var isFolder: Bool

    init(
        path: Path,
        isFolder: Bool = false
    ) {
        self.path = path
        self.isFolder = isFolder
    }

    // MARK: Decodable

    init(from decoder: Decoder) throws {
        path = try decoder.singleValueContainer().decode(Path.self)
        isFolder = false
    }
}

extension FilePath {
    func parent() -> FilePath {
        return FilePath(
            path: path.parent().normalize(),
            isFolder: false
        )
    }
}

// MARK: Comparable

extension FilePath: Comparable {
    static func < (lhs: FilePath, rhs: FilePath) -> Bool {
        guard lhs.path == rhs.path else {
            return lhs.path < rhs.path
        }
        return lhs.isFolder
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
        path: path,
        isFolder: false
    )
}
