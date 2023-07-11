import CustomDump
import GeneratorCommon
import XCTest

@testable import pbxproject_targets

class CalculateCreatedOnToolsVersionTests: XCTestCase {
    func test() {
        // Arrange

        let minimumXcodeVersion: SemanticVersion = "14.3.1"

        let expectedCreatedOnToolsVersion = "14.3.1"

        // Act

        let createdOnToolsVersion = Generator.CalculateCreatedOnToolsVersion
            .defaultCallable(minimumXcodeVersion: minimumXcodeVersion)

        // Assert

        XCTAssertNoDifference(
            createdOnToolsVersion,
            expectedCreatedOnToolsVersion
        )
    }
}
