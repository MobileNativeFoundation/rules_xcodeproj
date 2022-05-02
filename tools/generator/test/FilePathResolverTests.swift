import PathKit
import XCTest

@testable import generator

class FilePathResolverTests: XCTestCase {
    let internalDirectoryName = "internal_name"
    let workspaceOutputPath = Path("path/to/Foo.xcodeproj")
    lazy var resolver = FilePathResolver(
        internalDirectoryName: internalDirectoryName,
        workspaceOutputPath: workspaceOutputPath
    )

    func test_containerReference() throws {
        XCTAssertEqual(
            resolver.containerReference,
            "container:\(workspaceOutputPath)"
        )
    }
}
