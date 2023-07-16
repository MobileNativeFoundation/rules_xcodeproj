import CustomDump
import XCTest

@testable import pbxproject_targets

class CalculateTargetsPartialTests: XCTestCase {
    func test_basic() {
        // Arrange

        let identifiers: [String] = [
            "b_id /* b */",
            "a_id /* a */",
            "c_id /* @//z:c */",
        ]

        // Shows that it's not responsible for sorting (this order is wrong)
        // The tabs for indenting are intentional
        let expectedTargetsPartial = #"""
			targets = (
				b_id /* b */,
				a_id /* a */,
				c_id /* @//z:c */,
			);
		};

"""#

        // Act

        let targetsPartial = Generator.CalculateTargetsPartial.defaultCallable(
            identifiers: identifiers
        )

        // Assert

        XCTAssertNoDifference(
			targetsPartial,
			expectedTargetsPartial
		)
    }

    func test_empty() {
        // Arrange
        
        let identifiers: [String] = []

        // The tabs for indenting are intentional
        let expectedTargetsPartial = #"""
			targets = (
			);
		};

"""#

        // Act

        let targetsPartial = Generator.CalculateTargetsPartial.defaultCallable(
            identifiers: identifiers
        )

        // Assert

        XCTAssertNoDifference(
			targetsPartial,
			expectedTargetsPartial
		)
    }
}
