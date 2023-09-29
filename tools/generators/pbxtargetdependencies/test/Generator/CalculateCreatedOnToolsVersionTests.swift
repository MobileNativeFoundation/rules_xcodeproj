import ToolCommon
import XCTest

@testable import pbxtargetdependencies

class CalculateCreatedOnToolsVersionTests: XCTestCase {
    func test() {
        // Arrange

        let minimumXcodeVersion: SemanticVersion = "14.3.1"

        let expectedCreatedOnToolsVersion = "14.3.1"

        // Act

        let createdOnToolsVersion = Generator.CalculateCreatedOnToolsVersion
            .defaultCallable(minimumXcodeVersion: minimumXcodeVersion)

        // Assert

        XCTAssertEqual(createdOnToolsVersion, expectedCreatedOnToolsVersion)
    }
}
