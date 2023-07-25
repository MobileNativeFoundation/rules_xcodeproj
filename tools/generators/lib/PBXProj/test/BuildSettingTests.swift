import CustomDump
import PBXProj
import XCTest

final class BuildSettingTests: XCTestCase {
    func test_comparable() {
        // Arrange

        let buildSettings: [BuildSetting] = [
            .init(key: "B", value: "BVALUE"),
            .init(
                key: "A[sdk=macosx*]",
                pbxProjEscapedKey: #""A[sdk=macosx*]""#,
                value: "AVALUE"
            ),
            .init(key: "A", value: "AVALUE"),
        ]

        let expectedSorted: [BuildSetting] = [
            .init(key: "A", value: "AVALUE"),
            .init(
                key: "A[sdk=macosx*]",
                pbxProjEscapedKey: #""A[sdk=macosx*]""#,
                value: "AVALUE"
            ),
            .init(key: "B", value: "BVALUE"),
        ]

        // Act

        let sorted = buildSettings.sorted()

        // Assert

        XCTAssertNoDifference(sorted, expectedSorted)
    }
}
