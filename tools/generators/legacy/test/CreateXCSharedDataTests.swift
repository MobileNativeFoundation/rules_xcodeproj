import CustomDump
import XcodeProj
import XCTest

@testable import generator

final class CreateXCSharedDataTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let schemes = Fixtures.xcSchemes()

        let expectedSharedData = XCSharedData(schemes: schemes)

        // Act

        let sharedData = Generator.createXCSharedData(schemes: schemes)

        // Assert

        XCTAssertNoDifference(sharedData, expectedSharedData)
    }
}
