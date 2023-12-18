import CustomDump
import XCTest

@testable import pbxtargetdependencies

class CreateTargetAttributesContentTests: XCTestCase {
    func test_basic() {
        // Arrange

        let createdOnToolsVersion = "13.0.0"
        let testHostIdentifierWithoutComment: String? = nil

        // Shows that it's not responsible for sorting (this order is wrong)
        // The tabs for indenting are intentional
        let expectedTargetAttributes = #"""
{
						CreatedOnToolsVersion = 13.0.0;
						LastSwiftMigration = 9999;
					}
"""#

        // Act

        let targetAttributes = Generator.CreateTargetAttributesContent
            .defaultCallable(
                createdOnToolsVersion: createdOnToolsVersion,
                testHostIdentifierWithoutComment:
                    testHostIdentifierWithoutComment
            )

        // Assert

        XCTAssertNoDifference(
            targetAttributes,
            expectedTargetAttributes
        )
    }

    func test_testHostIdentifierWithoutComment() {
        // Arrange

        let createdOnToolsVersion = "13.0.0"
        let testHostIdentifierWithoutComment = "testHost_id /* testHost */"

        // The tabs for indenting are intentional
        let expectedTargetAttributes = #"""
{
						CreatedOnToolsVersion = 13.0.0;
						LastSwiftMigration = 9999;
						TestTargetID = testHost_id /* testHost */;
					}
"""#

        // Act

        let targetAttributes = Generator.CreateTargetAttributesContent
            .defaultCallable(
                createdOnToolsVersion: createdOnToolsVersion,
                testHostIdentifierWithoutComment:
                    testHostIdentifierWithoutComment
            )

        // Assert

        XCTAssertNoDifference(
            targetAttributes,
            expectedTargetAttributes
		)
    }
}
