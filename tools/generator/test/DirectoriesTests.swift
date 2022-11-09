import PathKit
import XCTest

@testable import generator

class DirectoriesTests: XCTestCase {
    let workspaceDirectory: Path = "/Users/TimApple/project"
    let projectRootDirectory: Path = "/Users/TimApple"
    let externalDirectory: Path = "/some/bazel2/external"
    let bazelOutDirectory: Path = "/some/bazel2/bazel-out"
    let internalDirectoryName = "internal_name"
    let workspaceOutputPath: Path = "path/to/Foo.xcodeproj"

    lazy var directories = Directories(
        workspace: workspaceDirectory,
        projectRoot: projectRootDirectory,
        external: externalDirectory,
        bazelOut: bazelOutDirectory,
        internalDirectoryName: internalDirectoryName,
        workspaceOutput: workspaceOutputPath
    )

    func test_containerReference() throws {
        XCTAssertEqual(
            directories.containerReference,
            "container:\(workspaceDirectory + workspaceOutputPath)"
        )
    }
}
