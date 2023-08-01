import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateSpecialRootGroupElementTests: XCTestCase {
    func test_bazelGenerated() {
        // Arrange

        let specialRootGroupType = SpecialRootGroupType.bazelGenerated
        let childIdentifiers = [
            "a /* applebin_macos-darwin_arm64-dbg-ST-4bf02e38abc1 */",
            "1 /* darwin_arm64-dbg */",
        ]

        let expectedElement = Element(
            name: "Bazel Generated Files",
            object: .init(
                identifier: Identifiers.FilesAndGroups.bazelGeneratedFilesGroup,
                content: #"""
{
			isa = PBXGroup;
			children = (
				a /* applebin_macos-darwin_arm64-dbg-ST-4bf02e38abc1 */,
				1 /* darwin_arm64-dbg */,
			);
			name = "Bazel Generated Files";
			path = "bazel-out";
			sourceTree = SOURCE_ROOT;
		}
"""#
            ),
            sortOrder: .bazelGenerated
        )

        // Act

        let element = ElementCreator.CreateSpecialRootGroupElement.defaultCallable(
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: childIdentifiers
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }

    func test_legacyBazelExternal() {
        // Arrange

        let specialRootGroupType = SpecialRootGroupType.legacyBazelExternal
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

        let element = ElementCreator.CreateSpecialRootGroupElement.defaultCallable(
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: childIdentifiers
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }

    func test_siblingBazelExternal() {
        // Arrange

        let specialRootGroupType = SpecialRootGroupType.siblingBazelExternal
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

        let element = ElementCreator.CreateSpecialRootGroupElement.defaultCallable(
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: childIdentifiers
        )

        // Assert

        XCTAssertNoDifference(element, expectedElement)
    }
}
