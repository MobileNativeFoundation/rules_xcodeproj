import XCTest

@testable import xcschemes

class CalculateSchemeReferencedContainerTests: XCTestCase {
    func test() {
        // Arrange

        let installPath = "a/visonary.xcodeproj"
        let workspace = "/Users/TimApple/Star Board"

        let expectedReferencedContainer = """
container:/Users/TimApple/Star Board/a/visonary.xcodeproj
"""

        // Act

        let referencedContainer = Generator.CalculateSchemeReferencedContainer
            .defaultCallable(installPath: installPath, workspace: workspace)

        // Assert

        XCTAssertEqual(referencedContainer, expectedReferencedContainer)
    }
}
