import CustomDump
import Foundation
import PBXProj
import XCTest

@testable import files_and_groups

class CalculateBuildFilesPartialTests: XCTestCase {
    func test() {
        // Arrange

        let objects: [Object] = [
            .init(identifier: "ID_2", content: "{BUILDFILE_2}"),
            .init(identifier: "ID_1", content: "{BUILDFILE_1}"),
        ]

        // The tabs for indenting are intentional
        let expectedFilesAndGroupsPartial = #"""
		ID_2 = {BUILDFILE_2};
		ID_1 = {BUILDFILE_1};

"""#

        // Act

        let filesAndGroupsPartial = Generator.CalculateBuildFilesPartial
            .defaultCallable(objects: objects)

        // Assert

        XCTAssertNoDifference(
            filesAndGroupsPartial,
            expectedFilesAndGroupsPartial
        )
    }
}
