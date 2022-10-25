import PathKit
import XCTest

@testable import generator

class FilePathResolverTests: XCTestCase {
    let workspaceDirectory: Path = "/Users/TimApple/project"
    let projectRootDirectory: Path = "/Users/TimApple"
    let externalDirectory: Path = "/some/bazel2/external"
    let bazelOutDirectory: Path = "/some/bazel2/bazel-out"
    let internalDirectoryName = "internal_name"
    let workspaceOutputPath: Path = "path/to/Foo.xcodeproj"

    lazy var directories = FilePathResolver.Directories(
        workspace: workspaceDirectory,
        projectRoot: projectRootDirectory,
        external: externalDirectory,
        bazelOut: bazelOutDirectory,
        internalDirectoryName: internalDirectoryName,
        workspaceOutput: workspaceOutputPath
    )

    lazy var resolver = FilePathResolver(
        directories: directories
    )

    func test_containerReference() throws {
        XCTAssertEqual(
            resolver.containerReference,
            "container:\(workspaceDirectory + workspaceOutputPath)"
        )
    }
}
