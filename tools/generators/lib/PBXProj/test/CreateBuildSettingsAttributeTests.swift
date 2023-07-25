import CustomDump
import PBXProj
import XCTest

final class CreateBuildSettingsAttributeTests: XCTestCase {
    func test_empty() {
        // Arrange

        let buildSettings: [BuildSetting] = []

        let expectedAttribute = #"""
{
			}
"""#

        // Act

        let attribute = CreateBuildSettingsAttribute
            .defaultCallable(buildSettings: buildSettings)

        // Assert

        XCTAssertNoDifference(attribute, expectedAttribute)
    }

    func test_nonEmpty() {
        // Arrange

        let buildSettings: [BuildSetting] = [
            .init(key: "KEY_B", value: "VALUEB"),
            .init(
                key: "KEY_A[sdk=macosx*]",
                pbxProjEscapedKey: #""KEY_A[sdk=macosx*]""#,
                value: #""VALUE A""#
            ),
            .init(key: "KEY_A", value: #""VALUE A Base""#),
        ]

        let expectedAttribute = #"""
{
				KEY_A = "VALUE A Base";
				"KEY_A[sdk=macosx*]" = "VALUE A";
				KEY_B = VALUEB;
			}
"""#

        // Act

        let attribute = CreateBuildSettingsAttribute
            .defaultCallable(buildSettings: buildSettings)

        // Assert

        XCTAssertNoDifference(attribute, expectedAttribute)
    }
}
