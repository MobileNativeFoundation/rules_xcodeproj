import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateInlineBazelGeneratedFilesElementTests: XCTestCase {
    
    func test() throws {
        
        let result = ElementCreator.CreateInlineBazelGeneratedFilesElement.defaultCallable(
            path: "bazel-out/ios-sim-123",
            childIdentifiers: [],
            createIdentifier: .stub(identifier: "id-123")
        )
        
		let expectedContent = #"""
{
			isa = PBXGroup;
			children = (
			);
			name = "Bazel Generated";
			path = "bazel-out/ios-sim-123";
			sourceTree = SOURCE_ROOT;
		}
"""#

        XCTAssertEqual(result.name, "Bazel Generated")
        XCTAssertEqual(result.sortOrder, .inlineBazelGenerated)
        XCTAssertEqual(result.object.identifier, "id-123")
        XCTAssertNoDifference(result.object.content, expectedContent)
    }
}
