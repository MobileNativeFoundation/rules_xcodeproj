import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateMainGroupContentTests: XCTestCase {
    func test_childIdentifiers() {
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

        let content = createMainGroupContentWithDefaults(
            childIdentifiers: childIdentifiers,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(content, expectedContent)
    }

    func test_indents_usesSpaces() {
        // Arrange

        let indentWidth: UInt? = 2
        let tabWidth: UInt? = 3
        let usesTabs: Bool? = false
        let workspace = "/tmp/workspace"

        // Shows that it's not responsible for sorting (this order is wrong)
        let expectedContent = #"""
{
			isa = PBXGroup;
			children = (
				FF0000000000000000000004 /* Products */,
				FF0000000000000000000005 /* Frameworks */,
			);
			indentWidth = 2;
			path = /tmp/workspace;
			sourceTree = "<absolute>";
			tabWidth = 3;
			usesTabs = 0;
		}
"""#

        // Act

        let content = createMainGroupContentWithDefaults(
            indentWidth: indentWidth,
            tabWidth: tabWidth,
            usesTabs: usesTabs,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(content, expectedContent)
    }

    func test_indents_usesTabs() {
        // Arrange

        let tabWidth: UInt? = 5
        let usesTabs: Bool? = true
        let workspace = "/tmp/workspace"

        // Shows that it's not responsible for sorting (this order is wrong)
        let expectedContent = #"""
{
			isa = PBXGroup;
			children = (
				FF0000000000000000000004 /* Products */,
				FF0000000000000000000005 /* Frameworks */,
			);
			path = /tmp/workspace;
			sourceTree = "<absolute>";
			tabWidth = 5;
			usesTabs = 1;
		}
"""#

        // Act

        let content = createMainGroupContentWithDefaults(
            tabWidth: tabWidth,
            usesTabs: usesTabs,
            workspace: workspace
        )

        // Assert

        XCTAssertNoDifference(content, expectedContent)
    }
}

private func createMainGroupContentWithDefaults(
    childIdentifiers: [String] = [],
    indentWidth: UInt? = nil,
    tabWidth: UInt? = nil,
    usesTabs: Bool? = nil,
    workspace: String
) -> String {
    return ElementCreator.CreateMainGroupContent.defaultCallable(
        childIdentifiers: childIdentifiers,
        indentWidth: indentWidth,
        tabWidth: tabWidth,
        usesTabs: usesTabs,
        workspace: workspace
    )
}
