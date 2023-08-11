import CustomDump
import XCTest

@testable import pbxtargetdependencies

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
				FF0100000000000000000001 /* BazelDependencies */,
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
				FF0100000000000000000001 /* BazelDependencies */,
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
