import PathKit

struct FilePathResolver: Equatable {
    enum Mode {
        case buildSetting
        case script
        case srcRoot
    }

    let workspaceDirectoryComponents: [String]
    
    let externalDirectory: Path
    let absoluteExternalDirectory: Path
    let bazelOutDirectory: Path

    let internalDirectoryName: String
    private let workspaceOutputPath: Path
    let internalDirectory: Path
    private let linksDirectory: Path

    /// In XcodeProj, a `referencedContainer` in a `XCScheme.BuildableReference`
    /// accepts a string in the format `container:<path-to-xcodeproj-dir>`. This
    /// property provides the value.
    let containerReference: String

    init(
        workspaceDirectory: Path,
        externalDirectory: Path,
        bazelOutDirectory: Path,
        internalDirectoryName: String,
        workspaceOutputPath: Path
    ) {
        self.workspaceDirectoryComponents = workspaceDirectory.components
        self.externalDirectory = externalDirectory
        self.bazelOutDirectory = bazelOutDirectory
        self.internalDirectoryName = internalDirectoryName
        self.workspaceOutputPath = workspaceOutputPath
        internalDirectory = workspaceOutputPath + internalDirectoryName
        linksDirectory = internalDirectory + "links"
        containerReference = "container:\(workspaceOutputPath)"

        if externalDirectory.isRelative {
            self.absoluteExternalDirectory = workspaceDirectory +
                externalDirectory
        } else {
            self.absoluteExternalDirectory = externalDirectory
        }
    }

    func resolve(
        _ filePath: FilePath,
        useBazelOut: Bool = false,
        forceAbsoluteProjectPath: Bool = false,
        mode: Mode = .buildSetting
    ) throws -> Path {
        switch filePath.type {
        case .project:
            let projectDir: Path
            switch mode {
            case .buildSetting:
                projectDir = forceAbsoluteProjectPath ? "$(PROJECT_DIR)" : ""
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
                externalDir = externalDirectory
            }
            return externalDir + filePath.path
        case .generated:
            if useBazelOut {
                let bazelOutDir: Path
                switch mode {
                case .buildSetting:
                    bazelOutDir = "$(BAZEL_OUT)"
                case .script:
                    bazelOutDir = "$BAZEL_OUT"
                case .srcRoot:
                    bazelOutDir = bazelOutDirectory
                }
                return bazelOutDir + filePath.path
            } else {
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
