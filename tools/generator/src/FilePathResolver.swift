import PathKit

final class FilePathResolver {
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

    // TODO: Make thread safe if we ever go concurrent
    private var memoizedPaths: [FilePath: String] = [:]

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

    func resolve(_ filePath: FilePath) -> String {
        if let memoized = memoizedPaths[filePath] {
            return memoized
        }

        let path: String
        switch filePath.type {
        case .project:
            guard filePath.path.normalize() != "." else {
                // We need to use Bazel's execution root for ".", since includes
                // can reference things like "external/" and "bazel-out"
                return "$(PROJECT_DIR)"
            }

            path = "$(SRCROOT)/\(filePath.path)"
        case .external:
            path = "$(BAZEL_EXTERNAL)/\(filePath.path)"
        case .generated:
            path = "$(BAZEL_OUT)/\(filePath.path)"
        case .internal:
            path = "$(INTERNAL_DIR)/\(filePath.path)"
        }

        memoizedPaths[filePath] = path
        return path
    }
}
