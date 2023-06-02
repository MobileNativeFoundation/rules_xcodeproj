import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class MainGroupTests: XCTestCase {
    func test() {
        // Arrange

        let rootElements: [Element] = [
            .init(
                identifier: "i /* internal */",
                content: "",
                sortOrder: .rulesXcodeprojInternal
            ),
            .init(
                identifier: "a1 /* file_or_folder1 */",
                content: "",
                sortOrder: .fileLike
            ),
            .init(
                identifier: "b /* bazel-out */",
                content: "",
                sortOrder: .bazelGenerated
            ),
            .init(
                identifier: "a2 /* file_or_folder1 */",
                content: "",
                sortOrder: .groupLike
            ),
            .init(
                identifier: "a3 /* file_or_folder2 */",
                content: "",
                sortOrder: .fileLike
            ),
            .init(
                identifier: "e /* ../../external */",
                content: "",
                sortOrder: .bazelExternalRepositories
            ),
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
			);
			path = /tmp/workspace;
			sourceTree = "<absolute>";
		}
"""#

        // Act

        let content = ElementCreator.mainGroup(
            rootElements: rootElements,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(content, expectedContent)
    }
}
