import CustomDump
import Foundation
import XCTest

@testable import files_and_groups
@testable import PBXProj

class CalculateTargetFilesPartialTests: XCTestCase {
    func test() {
        // Arrange

        let objects: [TargetFileObject] = [
            .product(
                subIdentifier: .init(
                    shard: "01",
                    type: .product,
                    path: "x.app",
                    hash: "2"
                ),
                identifier: "P_ID_1 /* x.app */"
            ),
            .buildFile(.init(identifier: "ID_2", content: "{BUILDFILE_2}")),
            .buildFile(.init(identifier: "ID_1", content: "{BUILDFILE_1}")),
            .product(
                subIdentifier: .init(
                    shard: "04",
                    type: .product,
                    path: "a",
                    hash: "0"
                ),
                identifier: "P_ID_3 /* a */"
            ),
            .product(
                subIdentifier: .init(
                    shard: "04",
                    type: .product,
                    path: "a",
                    hash: "0"
                ),
                identifier: "P_ID_2 /* a */"
            ),
        ]

        // The tabs for indenting are intentional
        let expectedFilesAndGroupsPartial = #"""
		ID_2 = {BUILDFILE_2};
		ID_1 = {BUILDFILE_1};
		FF0000000000000000000004 /* Products */ = {
			isa = PBXGroup;
			children = (
				P_ID_2 /* a */,
				P_ID_3 /* a */,
				P_ID_1 /* x.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};

"""#

        // Act

        let filesAndGroupsPartial = Generator.CalculateTargetFilesPartial
            .defaultCallable(objects: objects)

        // Assert

        XCTAssertNoDifference(
            filesAndGroupsPartial,
            expectedFilesAndGroupsPartial
        )
    }
}
