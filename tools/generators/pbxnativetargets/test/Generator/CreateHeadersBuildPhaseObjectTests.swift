import CustomDump
import XCTest

@testable import pbxnativetargets
@testable import PBXProj

class CreateHeadersBuildPhaseObjectTests: XCTestCase {
    func test() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let buildFileIdentifiers = [
            "D_ID /* D.h in Headers */",
            "R_ID /* R.h in Headers */",
            "P_ID /* P.h in Headers */",
        ]

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: #"""
A_SHARD00A_HASH000000000006 /* Headers */
"""#,
            content: #"""
{
			isa = PBXHeadersBuildPhase;
			buildActionMask = 2147483647;
			files = (
				D_ID /* D.h in Headers */,
				R_ID /* R.h in Headers */,
				P_ID /* P.h in Headers */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}
"""#
        )

        // Act

        let object = Generator.CreateHeadersBuildPhaseObject
            .defaultCallable(
                subIdentifier: subIdentifier,
                buildFileIdentifiers: buildFileIdentifiers
            )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
