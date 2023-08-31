import CustomDump
import XCScheme
import XCTest

final class CreateArchiveActionTests: XCTestCase {
    func test() {
        // Arrange

        let buildConfiguration = "Release"

        let expectedAction = #"""
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
"""#

        // Act

        let action = CreateArchiveAction.defaultCallable(
            buildConfiguration: buildConfiguration
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }
}
