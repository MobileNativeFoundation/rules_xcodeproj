import CustomDump
import XCScheme
import XCTest

final class CreateAnalyzeActionTests: XCTestCase {
    func test() {
        // Arrange

        let buildConfiguration = "AppStore"

        let expectedAction = #"""
   <AnalyzeAction
      buildConfiguration = "AppStore">
   </AnalyzeAction>
"""#

        // Act

        let action = CreateAnalyzeAction.defaultCallable(
            buildConfiguration: buildConfiguration
        )

        // Assert

        XCTAssertNoDifference(action, expectedAction)
    }
}
