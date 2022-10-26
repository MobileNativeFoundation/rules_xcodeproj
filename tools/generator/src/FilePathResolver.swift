import PathKit

final class FilePathResolver {
    enum Mode {
        case buildSetting
        case script
        case srcRoot
    }

    struct Directories: Equatable {
        let workspace: Path
        let workspaceComponents: [String]
        let workspaceOutput: Path

        let internalDirectoryName: String
        let `internal`: Path

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
            workspaceOutput: Path
        ) {
            self.workspace = workspace
            workspaceComponents = workspace.components
            self.workspaceOutput = workspaceOutput

            self.internalDirectoryName = internalDirectoryName
            `internal` = workspaceOutput + internalDirectoryName

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

    struct MemoizationKey: Equatable, Hashable {
        let filePath: FilePath
        let transformedFilePath: FilePath
        let useBazelOut: Bool?
        let forceFullBuildSettingPath: Bool
        let mode: FilePathResolver.Mode
    }

    // TODO: Make thread safe if we ever go concurrent
    private var memoizedPaths: [MemoizationKey: Path] = [:]

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

        let workspace: Path
        if directories.bazelOut.isRelative {
            workspace = Path(
                components: (0 ..< (directories.bazelOut.components.count - 1))
                    .map { _ in ".." }
            )
        } else {
            workspace = directories.workspace
        }
        containerReference = """
container:\(workspace + directories.workspaceOutput)
"""
    }

    func resolve(
        _ filePath: FilePath,
        transform: (_ filePath: FilePath) -> FilePath = { $0 },
        xcodeGeneratedTransform: ((_ filePath: FilePath) -> FilePath)? = nil,
        useBazelOut: Bool? = nil,
        forceFullBuildSettingPath: Bool = false,
        mode: Mode = .buildSetting
    ) throws -> Path {
        func memoizationKey(_ transformedFilePath: FilePath) -> MemoizationKey {
            return .init(
                filePath: filePath,
                transformedFilePath: transformedFilePath,
                useBazelOut: useBazelOut,
                forceFullBuildSettingPath: forceFullBuildSettingPath,
                mode: mode
            )
        }

        let key: MemoizationKey
        let path: Path
        switch filePath.type {
        case .project:
            guard filePath.path.normalize() != "." else {
                // We need to use Bazel's execution root for ".", since includes
                // can reference things like "external/" and "bazel-out"
                return "$(PROJECT_DIR)"
            }

            let transformedFilePath = transform(filePath)

            key = memoizationKey(transformedFilePath)
            if let memoized = memoizedPaths[key] {
                return memoized
            }

            let projectDir: Path
            switch mode {
            case .buildSetting:
                projectDir = forceFullBuildSettingPath ? "$(SRCROOT)" : ""
            case .script:
                projectDir = "$SRCROOT"
            case .srcRoot:
                projectDir = ""
            }
            path = projectDir + transformedFilePath.path
        case .external:
            let transformedFilePath = transform(filePath)

            key = memoizationKey(transformedFilePath)
            if let memoized = memoizedPaths[key] {
                return memoized
            }

            let externalDir: Path
            switch mode {
            case .buildSetting:
                externalDir = forceFullBuildSettingPath ?
                    "$(BAZEL_EXTERNAL)" : "external"
            case .script:
                externalDir = "$BAZEL_EXTERNAL"
            case .srcRoot:
                externalDir = directories.external
            }
            path = externalDir + transformedFilePath.path
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

            key = memoizationKey(generatedFilePath)
            if let memoized = memoizedPaths[key] {
                return memoized
            }

            if actuallyUseBazelOut {
                let bazelOutDir: Path
                switch mode {
                case .buildSetting:
                    bazelOutDir = forceFullBuildSettingPath ?
                        "$(BAZEL_OUT)" : "bazel-out"
                case .script:
                    bazelOutDir = "$BAZEL_OUT"
                case .srcRoot:
                    bazelOutDir = directories.bazelOut
                }
                path = bazelOutDir + generatedFilePath.path
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
                path = buildDir + "bazel-out" + generatedFilePath.path
            }
        case .internal:
            let transformedFilePath = transform(filePath)

            key = memoizationKey(transformedFilePath)
            if let memoized = memoizedPaths[key] {
                return memoized
            }

            let internalDir: Path
            switch mode {
            case .buildSetting:
                internalDir = "$(INTERNAL_DIR)"
            case .script:
                internalDir = "$INTERNAL_DIR"
            case .srcRoot:
                internalDir = directories.internal
            }
            path = internalDir + transformedFilePath.path
        }

        memoizedPaths[key] = path
        return path
    }
}
