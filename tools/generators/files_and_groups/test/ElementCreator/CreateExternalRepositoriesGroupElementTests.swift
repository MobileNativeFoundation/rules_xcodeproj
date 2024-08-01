import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateExternalRepositoriesGroupElementTests: XCTestCase {
    func test() {
        // Arrange

        let childIdentifiers = [
            "2 /* _main~com_github_pointfreeco_swift_custom_dump */",
            "b /* rules_apple~2.0.0 */",
        ]

        let expectedElement = Element(
            name: "Bazel External Repositories",
            object: .init(
                identifier:
                    Identifiers.FilesAndGroups.bazelExternalRepositoriesGroup,
                content: #"""
{
			isa = PBXGroup;
			children = (
				2 /* _main~com_github_pointfreeco_swift_custom_dump */,
				b /* rules_apple~2.0.0 */,
			);
			name = "Bazel External Repositories";
			path = ../../external;
			sourceTree = SOURCE_ROOT;
		}
"""#
            ),
            sortOrder: .bazelExternalRepositories
        )

        // Act

        let element = ElementCreator.CreateExternalRepositoriesGroupElement
            .defaultCallable(childIdentifiers: childIdentifiers)

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }
}
