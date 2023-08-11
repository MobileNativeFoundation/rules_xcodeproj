import CustomDump
import XCTest

@testable import pbxnativetargets
@testable import PBXProj

class CreateSourcesBuildPhaseObjectTests: XCTestCase {
    func test() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let buildFileIdentifiers = [
            "D_ID /* D.swift in Sources */",
            "R_ID /* R.swift in Sources */",
            "P_ID /* P.swift in Sources */",
        ]

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: #"""
A_SHARD00A_HASH000000000007 /* Sources */
"""#,
            content: #"""
{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				D_ID /* D.swift in Sources */,
				R_ID /* R.swift in Sources */,
				P_ID /* P.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}
"""#
        )

        // Act

        let object = Generator.CreateSourcesBuildPhaseObject
            .defaultCallable(
                subIdentifier: subIdentifier,
                buildFileIdentifiers: buildFileIdentifiers
            )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
