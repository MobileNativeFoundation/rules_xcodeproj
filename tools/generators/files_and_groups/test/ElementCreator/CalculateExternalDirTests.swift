import XCTest

@testable import files_and_groups

final class CalculateExternalDirTests: XCTestCase {
    func test() throws {
        // Arrange

        let executionRoot = "/output_base/execroot/_main"

        let expectedExternalDir = "/output_base/external"

        // Act

        let externalDir = try ElementCreator.CalculateExternalDir
            .defaultCallable(executionRoot: executionRoot)

        // Assert

        XCTAssertEqual(externalDir, expectedExternalDir)
    }
}
