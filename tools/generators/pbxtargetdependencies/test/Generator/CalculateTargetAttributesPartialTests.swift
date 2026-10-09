import CustomDump
import PBXProj
import XCTest

@testable import pbxtargetdependencies

class CalculateTargetAttributesPartialTests: XCTestCase {
    func test_basic() {
        // Arrange

        let objects: [Object] = [
            .init(identifier: "b_id /* b */", content: "{b_content}"),
            .init(identifier: "a_id /* a */", content: "{a_content}"),
            .init(identifier: "c_id /* @//z:c */", content: "{c_content}"),
        ]

        // Sorted by identifier, like Xcode does
        // The tabs for indenting are intentional
        let expectedTargetAttributesPartial = #"""
				TargetAttributes = {
					a_id /* a */ = {a_content};
					b_id /* b */ = {b_content};
					c_id /* @//z:c */ = {c_content};
				};
			};

"""#

        // Act

        let targetAttributesPartial = Generator.CalculateTargetAttributesPartial
            .defaultCallable(objects: objects)

        // Assert

        XCTAssertNoDifference(
            targetAttributesPartial,
            expectedTargetAttributesPartial
		)
    }

    func test_empty() {
        // Arrange

        let objects: [Object] = []

        // The tabs for indenting are intentional
        let expectedTargetAttributesPartial = #"""
				TargetAttributes = {
				};
			};

"""#

        // Act

        let targetAttributesPartial = Generator.CalculateTargetAttributesPartial
            .defaultCallable(objects: objects)

        // Assert

        XCTAssertNoDifference(
            targetAttributesPartial,
            expectedTargetAttributesPartial
		)
    }
}
