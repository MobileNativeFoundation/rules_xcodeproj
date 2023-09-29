import CustomDump
import XCTest

@testable import pbxnativetargets
@testable import PBXProj

class CreateBuildConfigurationObjectTests: XCTestCase {
    func test_escaped() {
        // Arrange

        let name = "App Store"
        let index: UInt8 = 0x42
        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let buildSettings = "{BUILD_SETTINGS}"

        let expectedObject = Object(
            identifier: "A_SHARD00A_HASH000000000142 /* App Store */",
            content: #"""
{
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS};
			name = "App Store";
		}
"""#
        )

        // Act

        let object = Generator.CreateBuildConfigurationObject.defaultCallable(
            name: name,
            index: index,
            subIdentifier: subIdentifier,
            buildSettings: buildSettings
        )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }

    func test_notEscaped() {
        // Arrange

        let name = "Debug"
        let index: UInt8 = 0x42
        let subIdentifier = Identifiers.Targets.SubIdentifier(
            shard: "A_SHARD",
            hash: "A_HASH"
        )
        let buildSettings = "{BUILD_SETTINGS}"

        let expectedObject = Object(
            identifier: "A_SHARD00A_HASH000000000142 /* Debug */",
            content: #"""
{
			isa = XCBuildConfiguration;
			buildSettings = {BUILD_SETTINGS};
			name = Debug;
		}
"""#
        )

        // Act

        let object = Generator.CreateBuildConfigurationObject.defaultCallable(
            name: name,
            index: index,
            subIdentifier: subIdentifier,
            buildSettings: buildSettings
        )

        // Assert

        XCTAssertNoDifference(object, expectedObject)
    }
}
