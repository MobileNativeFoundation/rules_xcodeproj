import PathKit

struct FilePathResolver: Equatable {
    enum Mode {
        case buildSetting
        case script
        case srcRoot
    }

    struct Directories: Equatable {
        let workspaceComponents: [String]
        let workspaceOutput: Path

        let internalDirectoryName: String
        let `internal`: Path
        let bazelIntegration: Path

        let projectRoot: Path
        let external: Path
        let absoluteExternal: Path
        let bazelOut: Path

        init(
            workspace: Path,
            projectRoot: Path,
            external: Path,
            bazelOut: Path,
            internalDirectoryName: String,
            bazelIntegration: Path,
            workspaceOutput: Path
        ) {
            workspaceComponents = workspace.components
            self.workspaceOutput = workspaceOutput

            self.internalDirectoryName = internalDirectoryName
            `internal` = workspaceOutput + internalDirectoryName
            self.bazelIntegration = bazelIntegration

            self.projectRoot = projectRoot
            self.external = external
            self.bazelOut = bazelOut

            if external.isRelative {
                absoluteExternal = workspace + external
            } else {
                absoluteExternal = external
            }
        }
    }

    private let directories: Directories

    /// In XcodeProj, a `referencedContainer` in a `XCScheme.BuildableReference`
    /// accepts a string in the format `container:<path-to-xcodeproj-dir>`. This
    /// property provides the value.
    let containerReference: String

    let xcodeGeneratedFiles: [FilePath: FilePath]

    init(
        directories: Directories,
        xcodeGeneratedFiles: [FilePath: FilePath] = [:]
    ) {
        self.directories = directories
        self.xcodeGeneratedFiles = xcodeGeneratedFiles

        containerReference = "container:\(directories.workspaceOutput)"
    }

    func resolve(
        _ filePath: FilePath,
        transform: (_ filePath: FilePath) -> FilePath = { $0 },
        xcodeGeneratedTransform: ((_ filePath: FilePath) -> FilePath)? = nil,
        useBazelOut: Bool? = nil,
        forceFullBuildSettingPath: Bool = false,
        mode: Mode = .buildSetting
    ) throws -> Path {
        switch filePath.type {
        case .project:
            let projectDir: Path
            switch mode {
            case .buildSetting:
                projectDir = forceFullBuildSettingPath ? "$(SRCROOT)" : ""
            case .script:
                projectDir = "$SRCROOT"
            case .srcRoot:
                projectDir = ""
            }
            return projectDir + transform(filePath).path
        case .external:
            let externalDir: Path
            switch mode {
            case .buildSetting:
                externalDir = "$(BAZEL_EXTERNAL)"
            case .script:
                externalDir = "$BAZEL_EXTERNAL"
            case .srcRoot:
                externalDir = directories.external
            }
            return externalDir + transform(filePath).path
        case .generated:
            let actuallyUseBazelOut: Bool
            let generatedFilePath: FilePath
            if let useBazelOut = useBazelOut {
                actuallyUseBazelOut = useBazelOut
                generatedFilePath = transform(filePath)
            } else if let xcodeFilePath = xcodeGeneratedFiles[filePath] {
                actuallyUseBazelOut = false

                if let xcodeGeneratedTransform = xcodeGeneratedTransform {
                    generatedFilePath = xcodeGeneratedTransform(xcodeFilePath)
                } else {
                    generatedFilePath = transform(xcodeFilePath)
                }
            } else {
                actuallyUseBazelOut = true
                generatedFilePath = transform(filePath)
            }

            if actuallyUseBazelOut {
                let bazelOutDir: Path
                switch mode {
                case .buildSetting:
                    bazelOutDir = "$(BAZEL_OUT)"
                case .script:
                    bazelOutDir = "$BAZEL_OUT"
                case .srcRoot:
                    bazelOutDir = directories.bazelOut
                }
                return bazelOutDir + generatedFilePath.path
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
                return buildDir + "bazel-out" + generatedFilePath.path
            }
        case .internal:
            let internalDir: Path
            switch mode {
            case .buildSetting:
                internalDir = "$(INTERNAL_DIR)"
            case .script:
                internalDir = "$INTERNAL_DIR"
            case .srcRoot:
                internalDir = directories.internal
            }
            return internalDir + transform(filePath).path
        }
    }
}
