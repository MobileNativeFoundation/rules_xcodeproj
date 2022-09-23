import PathKit
import XcodeProj

struct Product: Equatable, Decodable {
    let type: PBXProductType
    let name: String
    var path: FilePath
    var additionalPaths: [FilePath]
    let executableName: String?

    /// Custom initializer for easier testing.
    init(
        type: PBXProductType,
        name: String,
        path: FilePath,
        additionalPaths: [FilePath] = [],
        executableName: String? = nil
    ) {
        self.type = type
        self.name = name
        self.path = path
        self.additionalPaths = additionalPaths
        self.executableName = executableName
    }
}

extension Product {
    mutating func merge(oldPackageBinDir: Path, newPackageBinDir: Path) {
        let oldPath = path
        path.replacePackageBinDir(old: oldPackageBinDir, new: newPackageBinDir)

        if oldPath != path {
            additionalPaths.append(oldPath)
        }
    }

    func merging(oldPackageBinDir: Path, newPackageBinDir: Path) -> Product {
        var product = self
        product.merge(
            oldPackageBinDir: oldPackageBinDir,
            newPackageBinDir: newPackageBinDir
        )
        return product
    }
}

private extension FilePath {
    mutating func replacePackageBinDir(old: Path, new: Path) {
        guard type == .generated else {
            return
        }

        // Remove `bazel-out/` from path
        let old = old.string.dropFirst(10)

        let pathString = path.string
        guard pathString.hasPrefix(old) else {
            return
        }

        // Remove `bazel-out/` from path
        let new = new.string.dropFirst(10)

        path = Path("\(new)\(pathString.dropFirst(old.count))")
    }
}
