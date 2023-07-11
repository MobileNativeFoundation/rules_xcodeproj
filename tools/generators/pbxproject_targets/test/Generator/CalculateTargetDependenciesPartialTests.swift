import CustomDump
import XCTest

@testable import pbxproject_targets

class CalculateTargetDependenciesPartialTests: XCTestCase {
    func test_basic() {
        // Arrange

        let elements: [Element] = [
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
            .defaultCallable(elements: elements)

        // Assert

        XCTAssertNoDifference(
            targetDependenciesPartial,
			expectedTargetsPartial
		)
    }

    func test_empty() {
        // Arrange
        
        let elements: [Element] = []

        let expectedTargetsPartial = ""

        // Act

        let targetDependenciesPartial = Generator
            .CalculateTargetDependenciesPartial
            .defaultCallable(elements: elements)

        // Assert

        XCTAssertNoDifference(
			targetDependenciesPartial,
			expectedTargetsPartial
		)
    }
}
