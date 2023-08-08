import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateInternalGroupTests: XCTestCase {
    func test() {
        // Arrange

        let installPath = "some/project.xcodeproj"

        let expectedCompileStubObject = Object(
            identifier: Identifiers.FilesAndGroups.compileStub,
            content: #"""
{isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = _CompileStub_.m; sourceTree = DERIVED_FILE_DIR; }
"""#
        )
        let expectedElement = Element(
            name: "rules_xcodeproj",
            object: .init(
                identifier: "FF0000000000000000000008 /* rules_xcodeproj */",
                content: #"""
{
			isa = PBXGroup;
			children = (
				FF0000000000000000000009 /* _CompileStub_.m */,
			);
			name = rules_xcodeproj;
			path = some/project.xcodeproj/rules_xcodeproj;
			sourceTree = "<group>";
		}
"""#
            ),
            sortOrder: .rulesXcodeprojInternal
        )

        let expectedResult = GroupChild.elementAndChildren(
            .init(
                element: expectedElement,
                transitiveObjects: [
                    expectedCompileStubObject,
                    expectedElement.object,
                ],
                bazelPathAndIdentifiers: [
                    (
                        BazelPath(""),
                        "FF0000000000000000000009 /* _CompileStub_.m */"
                    ),
                ],
                knownRegions: [],
                resolvedRepositories: []
            )
        )

        // Act

        let result = ElementCreator.CreateInternalGroup.defaultCallable(
            installPath: installPath
        )

        // Assert

        XCTAssertNoDifference(result, expectedResult)
    }
}
