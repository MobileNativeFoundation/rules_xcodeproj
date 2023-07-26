import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateMainGroupContentTests: XCTestCase {
    func test() {
        // Arrange

        let childIdentifiers: [String] = [
            "i /* internal */",
            "a1 /* file_or_folder1 */",
            "b /* bazel-out */",
            "a2 /* file_or_folder1 */",
            "a3 /* file_or_folder2 */",
            "e /* ../../external */",
        ]
        let workspace = "/tmp/workspace"

        // Shows that it's not responsible for sorting (this order is wrong)
        let expectedContent = #"""
{
			isa = PBXGroup;
			children = (
				i /* internal */,
				a1 /* file_or_folder1 */,
				b /* bazel-out */,
				a2 /* file_or_folder1 */,
				a3 /* file_or_folder2 */,
				e /* ../../external */,
				FF0000000000000000000004 /* Products */,
				FF0000000000000000000005 /* Frameworks */,
			);
			path = /tmp/workspace;
			sourceTree = "<absolute>";
		}
"""#

        // Act

        let content = ElementCreator.CreateMainGroupContent.defaultCallable(
            childIdentifiers: childIdentifiers,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(content, expectedContent)
    }
}
