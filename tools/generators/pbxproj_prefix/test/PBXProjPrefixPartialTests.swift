import CustomDump
import Foundation
import PBXProj
import XCTest

@testable import pbxproj_prefix

class PBXProjPrefixPartialTests: XCTestCase {
    func test() {
        // Arrange

        let bazelDependenciesPartial = "{BazelDependencies_Partial}\n"
        let pbxProjectPrefixPartial = "{PBXProject_Prefix_Partial}\n"

        let expectedPbxProjPrefixPartial = #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 55;
	objects = {
{BazelDependencies_Partial}
{PBXProject_Prefix_Partial}

"""#

        // Act

        let pbxProjPrefixPartial = Generator.pbxProjPrefixPartial(
            bazelDependenciesPartial: bazelDependenciesPartial,
            pbxProjectPrefixPartial: pbxProjectPrefixPartial
        )

        // Assert

        XCTAssertNoDifference(
            pbxProjPrefixPartial,
            expectedPbxProjPrefixPartial
        )
    }
}
