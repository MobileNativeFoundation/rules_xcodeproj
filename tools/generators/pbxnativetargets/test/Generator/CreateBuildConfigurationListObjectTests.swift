import CustomDump
import XCTest

@testable import pbxnativetargets
@testable import PBXProj

class CreateBuildConfigurationListObjectTests: XCTestCase {
    func test() {
        // Arrange

        let name = "A"
        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let buildConfigurationIdentifiers = [
            "D_ID /* Debug */",
            "R_ID /* Release */",
            "P_ID /* Profile */",
        ]
        let defaultXcodeConfiguration = "Release"

        // The tabs for indenting are intentional
        let expectedObject = Object(
            identifier: #"""
A_SHARD00A_HASH000000000002 \#
/* Build configuration list for PBXNativeTarget "A" */
"""#,
            content: #"""
{
			isa = XCConfigurationList;
			buildConfigurations = (
				D_ID /* Debug */,
				R_ID /* Release */,
				P_ID /* Profile */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}
"""#
        )

        // Act

        let object = Generator.CreateBuildConfigurationListObject
            .defaultCallable(
                name: name,
                subIdentifier: subIdentifier,
                buildConfigurationIdentifiers: buildConfigurationIdentifiers,
                defaultXcodeConfiguration: defaultXcodeConfiguration
            )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
