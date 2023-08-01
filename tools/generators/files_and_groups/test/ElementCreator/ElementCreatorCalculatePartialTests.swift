import CustomDump
import Foundation
import PBXProj
import XCTest

@testable import files_and_groups

class ElementCreatorCalculatePartialTests: XCTestCase {
    func test_basic() {
        // Arrange

        let elements: [Element] = []
        let mainGroup = "{MAIN_GROUP_ELEMENT}"
        let workspace = "/Users/TimApple/Star Board"

        // The tabs for indenting are intentional
        let expectedElementsPartial = #"""
		FF0000000000000000000003 /* /Users/TimApple/Star Board */ = {MAIN_GROUP_ELEMENT};

"""#

        // Act

        let elementsPartial = ElementCreator.CalculatePartial.defaultCallable(
            elements: elements,
            mainGroup: mainGroup,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(
            elementsPartial,
            expectedElementsPartial
		)
    }

    func test_elements() {
        // Arrange

        let elements: [Element] = [
            .init(
                name: "i",
                object: .init(
                    identifier: "i /* internal */",
                    content: "{i_ELEMENT}"
                ),
                sortOrder: .rulesXcodeprojInternal
            ),
            .init(
                name: "a1",
                object: .init(
                    identifier: "a1 /* file_or_folder1 */",
                    content: "{a1_ELEMENT}"
                ),
                sortOrder: .fileLike
            ),
            .init(
                name: "b",
                object: .init(
                    identifier: "b /* bazel-out */",
                    content: "{b_ELEMENT}"
                ),
                sortOrder: .bazelGenerated
            ),
            .init(
                name: "a2",
                object: .init(
                    identifier: "a2 /* file_or_folder1 */",
                    content: "{a2_ELEMENT}"
                ),
                sortOrder: .groupLike
            ),
            .init(
                name: "a3",
                object: .init(
                    identifier: "a3 /* file_or_folder2 */",
                    content: "{a3_ELEMENT}"
                ),
                sortOrder: .fileLike
            ),
            .init(
                name: "e",
                object: .init(
                    identifier: "e /* ../../external */",
                    content: "{e_ELEMENT}"
                ),
                sortOrder: .bazelExternalRepositories
            ),
        ]
        let mainGroup = "{MAIN_GROUP_ELEMENT}"
        let workspace = "/Users/TimApple/StarBoard"

        // The tabs for indenting are intentional.
        //
        // Shows that it's not responsible for sorting (this order is wrong).
        let expectedElementsPartial = #"""
		FF0000000000000000000003 /* /Users/TimApple/StarBoard */ = {MAIN_GROUP_ELEMENT};
		i /* internal */ = {i_ELEMENT};
		a1 /* file_or_folder1 */ = {a1_ELEMENT};
		b /* bazel-out */ = {b_ELEMENT};
		a2 /* file_or_folder1 */ = {a2_ELEMENT};
		a3 /* file_or_folder2 */ = {a3_ELEMENT};
		e /* ../../external */ = {e_ELEMENT};

"""#

        // Act

        let elementsPartial = ElementCreator.CalculatePartial.defaultCallable(
            elements: elements,
            mainGroup: mainGroup,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(
            elementsPartial,
            expectedElementsPartial
		)
    }
}
