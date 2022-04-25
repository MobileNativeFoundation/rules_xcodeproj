import PathKit

struct FilePathResolver: Equatable {
    enum Mode {
        case buildSetting
        case script
        case srcRoot
    }


    let internalDirectoryName: String
    private let workspaceOutputPath: Path
    let internalDirectory: Path
    private let linksDirectory: Path

    init(internalDirectoryName: String, workspaceOutputPath: Path) {
        self.internalDirectoryName = internalDirectoryName
        self.workspaceOutputPath = workspaceOutputPath
        internalDirectory = workspaceOutputPath + internalDirectoryName
        linksDirectory = internalDirectory + "links"
    }

    func resolve(
        _ filePath: FilePath,
        useBuildDir: Bool = true,
        useOriginalGeneratedFiles: Bool = false,
        mode: Mode = .buildSetting
    ) throws -> Path {
        switch filePath.type {
        case .project:
            let projectDir: Path
            switch mode {
            case .buildSetting:
                projectDir = "$(PROJECT_DIR)"
            case .script:
                projectDir = "$PROJECT_DIR"
            case .srcRoot:
                projectDir = ""
            }
            return projectDir + filePath.path
        case .external:
            let externalDir: Path
            switch mode {
            case .buildSetting:
                externalDir = "$(BAZEL_EXTERNAL)"
            case .script:
                externalDir = "$BAZEL_EXTERNAL"
            case .srcRoot:
                externalDir = linksDirectory + "external"
            }
            return externalDir + filePath.path
        case .generated:
            if useOriginalGeneratedFiles {
                let bazelOutDir: Path
                switch mode {
                case .buildSetting:
                    bazelOutDir = "$(BAZEL_OUT)"
                case .script:
                    bazelOutDir = "$BAZEL_OUT"
                case .srcRoot:
                    throw PreconditionError(message: """
`useOriginalGeneratedFiles = true` and `mode` == `.srcRoot`
""")
                }
                return bazelOutDir + filePath.path
            } else if useBuildDir {
                let buildDir: Path
                switch mode {
                case .buildSetting:
                    buildDir = "$(BUILD_DIR)"
                case .script:
                    buildDir = "$BUILD_DIR"
                case .srcRoot:
                    throw PreconditionError(message: """
`useBuildDir = true` and `mode` == `.srcRoot`
""")
                }
                return buildDir + "bazel-out" + filePath.path
            } else {
                let copiedBazelOutDir: Path
                switch mode {
                case .buildSetting:
                    copiedBazelOutDir = "$(GEN_DIR)"
                case .script:
                    copiedBazelOutDir = "$GEN_DIR"
                case .srcRoot:
                    copiedBazelOutDir = linksDirectory + "gen_dir"
                }
                return copiedBazelOutDir + filePath.path
            }
        case .internal:
            let internalDir: Path
            switch mode {
            case .buildSetting:
                internalDir = "$(INTERNAL_DIR)"
            case .script:
                internalDir = "$INTERNAL_DIR"
            case .srcRoot:
                internalDir = internalDirectory
            }
            return internalDir + filePath.path
        }
    }
}
