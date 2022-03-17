import PathKit

struct FilePathResolver: Equatable {
    let externalDirectory: Path
    let generatedDirectory: Path
    let internalDirectoryName: String
    private let workspaceOutputPath: Path

    init(
        externalDirectory: Path,
        generatedDirectory: Path,
        internalDirectoryName: String,
        workspaceOutputPath: Path
    ) {
        self.externalDirectory = externalDirectory
        self.generatedDirectory = generatedDirectory
        self.internalDirectoryName = internalDirectoryName
        self.workspaceOutputPath = workspaceOutputPath
    }

    var internalDirectory: Path {
        return workspaceOutputPath + internalDirectoryName
    }

    func resolve(_ filePath: FilePath, useBuildDir: Bool = false) -> Path {
        switch filePath.type {
        case .project:
            return filePath.path
        case .external:
            return externalDirectory + filePath.path
        case .generated:
            if useBuildDir {
                return "$(BUILD_DIR)/bazel-out" + filePath.path
            } else {
                return generatedDirectory + filePath.path
            }
        case .internal:
            return internalDirectory + filePath.path
        }
    }
}
