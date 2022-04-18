import PathKit

struct FilePathResolver: Equatable {
    let internalDirectoryName: String
    private let workspaceOutputPath: Path

    init(internalDirectoryName: String, workspaceOutputPath: Path) {
        self.internalDirectoryName = internalDirectoryName
        self.workspaceOutputPath = workspaceOutputPath
    }

    var internalDirectory: Path {
        return workspaceOutputPath + internalDirectoryName
    }

    func resolve(
        _ filePath: FilePath,
        useBuildDir: Bool = true,
        useOriginalGeneratedFiles: Bool = false,
        useScriptVariables: Bool = false
    ) -> Path {
        switch filePath.type {
        case .project:
            let projectDir: Path
            if useScriptVariables {
                projectDir = "$PROJECT_DIR"
            } else {
                projectDir = "$(PROJECT_DIR)"
            }
            return projectDir + filePath.path
        case .external:
            let externalPath: Path
            if useScriptVariables {
                externalPath = "$BAZEL_EXTERNAL"
            } else {
                externalPath = "$(BAZEL_EXTERNAL)"
            }
            return externalPath + filePath.path
        case .generated:
            if useOriginalGeneratedFiles {
                let bazelOutPath: Path
                if useScriptVariables {
                    bazelOutPath = "$BAZEL_OUT"
                } else {
                    bazelOutPath = "$(BAZEL_OUT)"
                }
                return bazelOutPath + filePath.path
            } else if useBuildDir {
                let buildDir: Path
                if useScriptVariables {
                    buildDir = "$BUILD_DIR"
                } else {
                    buildDir = "$(BUILD_DIR)"
                }
                return buildDir + "bazel-out" + filePath.path
            } else {
                let copiedBazelOutPath: Path
                if useScriptVariables {
                    copiedBazelOutPath = "$GEN_DIR"
                } else {
                    copiedBazelOutPath = "$(GEN_DIR)"
                }
                return copiedBazelOutPath + filePath.path
            }
        case .internal:
            let internalPath: Path
            if useScriptVariables {
                internalPath = "$INTERNAL_DIR"
            } else {
                internalPath = "$(INTERNAL_DIR)"
            }
            return internalPath + filePath.path
        }
    }
}
