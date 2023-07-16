import CustomDump
import XCTest

@testable import pbxproject_targets

class CalculateTargetAttributesPartialTests: XCTestCase {
    func test_basic() {
        // Arrange

        let elements: [Element] = [
            .init(identifier: "b_id /* b */", content: "{b_content}"),
            .init(identifier: "a_id /* a */", content: "{a_content}"),
            .init(identifier: "c_id /* @//z:c */", content: "{c_content}"),
        ]

        // Shows that it's not responsible for sorting (this order is wrong)
        // The tabs for indenting are intentional
        let expectedTargetAttributesPartial = #"""
				TargetAttributes = {
					b_id /* b */ = {b_content};
					a_id /* a */ = {a_content};
					c_id /* @//z:c */ = {c_content};
				};
			};

"""#

        // Act

        let targetAttributesPartial = Generator.CalculateTargetAttributesPartial
            .defaultCallable(elements: elements)

        // Assert

        XCTAssertNoDifference(
            targetAttributesPartial,
            expectedTargetAttributesPartial
		)
    }

    func test_empty() {
        // Arrange
        
        let elements: [Element] = []

        // The tabs for indenting are intentional
        let expectedTargetAttributesPartial = #"""
				TargetAttributes = {
				};
			};

"""#

        // Act

        let targetAttributesPartial = Generator.CalculateTargetAttributesPartial
            .defaultCallable(elements: elements)

        // Assert

        XCTAssertNoDifference(
            targetAttributesPartial,
            expectedTargetAttributesPartial
		)
    }
}
