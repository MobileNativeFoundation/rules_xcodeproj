import CustomDump
import PBXProj
import XCTest

@testable import pbxtargetdependencies

class CalculateTargetDependenciesPartialTests: XCTestCase {
    func test_basic() {
        // Arrange

        let objects: [Object] = [
            .init(
                identifier: "b_id /* b */",
                content: "{B_CONTENT}"
            ),
            .init(
                identifier: "a_id /* a */",
                content: "{A_CONTENT}"
            ),
            .init(
                identifier: "c_id /* @//z:c */",
                content: "{C_CONTENT}"
            ),
        ]

        // Shows that it's not responsible for sorting (this order is wrong)
        // The tabs for indenting are intentional
        let expectedTargetsPartial = #"""
		b_id /* b */ = {B_CONTENT};
		a_id /* a */ = {A_CONTENT};
		c_id /* @//z:c */ = {C_CONTENT};

"""#

        // Act

        let targetDependenciesPartial = Generator
            .CalculateTargetDependenciesPartial
            .defaultCallable(objects: objects)

        // Assert

        XCTAssertNoDifference(targetDependenciesPartial,expectedTargetsPartial)
    }

    func test_empty() {
        // Arrange

        let objects: [Object] = []

        let expectedTargetsPartial = ""

        // Act

        let targetDependenciesPartial = Generator
            .CalculateTargetDependenciesPartial
            .defaultCallable(objects: objects)

        // Assert

        XCTAssertNoDifference(targetDependenciesPartial,expectedTargetsPartial)
    }
}
