import PathKit

struct Directories: Equatable {
    let workspace: Path
    let workspaceComponents: [String]
    let workspaceOutput: Path

    let internalDirectoryName: String
    let `internal`: Path

    let projectRoot: Path
    let absoluteExternal: Path
    let bazelOut: Path

    /// In XcodeProj, a `referencedContainer` in a `XCScheme.BuildableReference`
    /// accepts a string in the format `container:<path-to-xcodeproj-dir>`. This
    /// property provides the value.
    let containerReference: String

    init(
        workspace: Path,
        projectRoot: Path,
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
        self.bazelOut = bazelOut

        let external = bazelOut.parent().parent().parent() + "external"
        if external.isRelative {
            absoluteExternal = workspace + external
        } else {
            absoluteExternal = external
        }

        let containerWorkspace: Path
        if bazelOut.isRelative {
            containerWorkspace = Path(
                components: (0 ..< (bazelOut.components.count - 1))
                    .map { _ in ".." }
            )
        } else {
            containerWorkspace = workspace
        }
        containerReference = """
container:\(containerWorkspace + workspaceOutput)
"""
    }
}
