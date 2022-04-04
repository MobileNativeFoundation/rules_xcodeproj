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

    func resolve(
        _ filePath: FilePath,
        useBuildDir: Bool = true,
        useProjectDir: Bool = true
    ) -> Path {
        switch filePath.type {
        case .project:
            return "$(PROJECT_DIR)" + filePath.path
        case .external:
            let path = externalDirectory + filePath.path
            if useProjectDir && path.isRelative {
                return "$(PROJECT_DIR)" + path
            } else {
                return path
            }
        case .generated:
            if useBuildDir {
                return "$(BUILD_DIR)/bazel-out" + filePath.path
            } else {
                let path = generatedDirectory + filePath.path
                if useProjectDir && path.isRelative {
                    return "$(PROJECT_DIR)" + path
                } else {
                    return path
                }
            }
        case .internal:
            let path = internalDirectory + filePath.path
            if useProjectDir {
                return "$(PROJECT_DIR)" + path
            } else {
                return path
            }
        }
    }
}
