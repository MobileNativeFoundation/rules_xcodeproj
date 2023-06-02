import XCTest

@testable import files_and_groups

final class ExternalDirTests: XCTestCase {
    func test() throws {
        // Arrange

        let executionRoot = "/output_base/execroot/_main"

        let expectedExternalDir = "/output_base/external"

        // Act

        let externalDir = try ElementCreator.externalDir(
            executionRoot: executionRoot
        )

        // Assert

        XCTAssertEqual(externalDir, expectedExternalDir)
    }
}
