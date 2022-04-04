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
        useBuildDir: Bool = false,
        useOriginalGeneratedFiles: Bool = false,
        useScriptVariables: Bool = false
    ) -> Path {
        let projectDir: Path
        if useScriptVariables {
            projectDir = "$PROJECT_DIR"
        } else {
            projectDir = "$(PROJECT_DIR)"
        }

        switch filePath.type {
        case .project:
            return projectDir + filePath.path
        case .external:
            let path = externalDirectory + filePath.path
            if path.isRelative {
                return projectDir + path
            } else {
                return path
            }
        case .generated:
            if useOriginalGeneratedFiles {
                let path = generatedDirectory + filePath.path
                if path.isRelative {
                    return projectDir + path
                } else {
                    return path
                }
            } else if useBuildDir {
                let buildDir: Path
                if useScriptVariables {
                    buildDir = "$BUILD_DIR"
                } else {
                    buildDir = "$(BUILD_DIR)"
                }
                return buildDir + "bazel-out" + filePath.path
            } else {
                let projectFilePath: Path
                if useScriptVariables {
                    projectFilePath = "$PROJECT_FILE_PATH"
                } else {
                    projectFilePath = "$(PROJECT_FILE_PATH)"
                }
                return projectFilePath + internalDirectoryName + "gen_dir" +
                    filePath.path
            }
        case .internal:
            return projectDir + internalDirectory + filePath.path
        }
    }
}
