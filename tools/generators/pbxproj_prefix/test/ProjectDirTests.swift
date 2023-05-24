import XCTest

@testable import pbxproj_prefix

class ProjectDirTests: XCTestCase {
    func test_privatePrefix() {
        // Arrange

        let executionRoot = "/private/tmp/execution_root"
        let expectedProjectDir = "/tmp/execution_root"

        // Act

        let projectDir = Generator.projectDir(
            executionRoot: executionRoot
        )

        // Assert

        XCTAssertEqual(projectDir, expectedProjectDir)
    }

    func test_nonPrivatePrefix() {
        // Arrange

        let executionRoot = "/Users/TimApple/execution_root"
        let expectedProjectDir = "/Users/TimApple/execution_root"

        // Act

        let projectDir = Generator.projectDir(
            executionRoot: executionRoot
        )

        // Assert

        XCTAssertEqual(projectDir, expectedProjectDir)
    }
}
