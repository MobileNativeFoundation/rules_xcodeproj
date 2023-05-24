import XCTest

@testable import pbxproj_prefix

class IndexingProjectDirTests: XCTestCase {
    func test() {
        // Arrange

        let projectDir = "/some/path/to/build_output_base/execroot/_main"
        let expectedIndexingProjectDir = """
/some/path/to/indexbuild_output_base/execroot/_main
"""

        // Act

        let indexingProjectDir = Generator.indexingProjectDir(
            projectDir: projectDir
        )

        // Assert

        XCTAssertEqual(indexingProjectDir, expectedIndexingProjectDir)
    }
}
