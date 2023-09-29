import CustomDump
import XCTest

@testable import pbxnativetargets
@testable import PBXProj

class CreateEmbedAppExtensionsBuildPhaseObjectTests: XCTestCase {
    func test() {
        // Arrange

        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let buildFileIdentifiers = [
            "D_ID /* D.appex in Embed App Extensions */",
            "R_ID /* R.appex in Embed App Extensions */",
            "P_ID /* P.appex in Embed App Extensions */",
        ]

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: #"""
A_SHARD00A_HASH000000000009 /* Embed App Extensions */
"""#,
            content: #"""
{
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 13;
			files = (
				D_ID /* D.appex in Embed App Extensions */,
				R_ID /* R.appex in Embed App Extensions */,
				P_ID /* P.appex in Embed App Extensions */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}
"""#
        )

        // Act

        let object = Generator.CreateEmbedAppExtensionsBuildPhaseObject
            .defaultCallable(
                subIdentifier: subIdentifier,
                buildFileIdentifiers: buildFileIdentifiers
            )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
