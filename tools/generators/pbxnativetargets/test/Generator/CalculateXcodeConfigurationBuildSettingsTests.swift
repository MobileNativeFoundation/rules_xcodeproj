import CustomDump
import PBXProj
import XCTest

@testable import pbxnativetargets

final class CalculateXcodeConfigurationBuildSettingsTests: XCTestCase {
    func test_buildSettings() {
        // Arrange

        let platformBuildSettings: [PlatformBuildSettings] = [
            .init(
                platform: .watchOSDevice,
                conditionalFiles: [],
                buildSettings: [
                    .init(key: "KEY1", value: "VALUE1"),
                    .init(key: "KEY3", value: "VALUE3"),
                    .init(key: "KEY5", value: "VALUE5"),
                    .init(key: "KEY6", value: "VALUE6"),
                    .init(key: "WATCHOS_DEPLOYMENT_TARGET", value: "9.2"),
                ]
            ),
            .init(
                platform: .iOSDevice,
                conditionalFiles: [],
                buildSettings: [
                    .init(key: "KEY1", value: "VALUE1_Different"),
                    .init(key: "KEY4", value: "VALUE4_B"),
                    .init(key: "KEY5", value: "VALUE5"),
                    .init(key: "IPHONEOS_DEPLOYMENT_TARGET", value: "12.0"),
                ]
            ),
            .init(
                platform: .iOSSimulator,
                conditionalFiles: [],
                buildSettings: [
                    .init(key: "KEY1", value: "VALUE1"),
                    .init(key: "KEY2", value: "VALUE2"),
                    .init(key: "KEY3", value: "VALUE3"),
                    .init(key: "KEY4", value: "VALUE4_A"),
                    .init(key: "KEY5", value: "VALUE5_Different"),
                    .init(key: "IPHONEOS_DEPLOYMENT_TARGET", value: "11.3.1"),
                ]
            ),
        ]
        let allConditionalFiles: Set<BazelPath> = []

        // Order of conditionals is wrong, but this is to show that the function
        // doesn't sort, and expects `platformVariantBuildSettings` to be
        // pre-sorted
        let expectedBuildSettings: [String: String] = [
            "KEY1": "VALUE1",
            "KEY1[sdk=iphoneos*]".quoted: "VALUE1_Different",
            "KEY2[sdk=iphonesimulator*]".quoted: "VALUE2",
            "KEY3[sdk=iphonesimulator*]".quoted: "VALUE3",
            "KEY3[sdk=watchos*]".quoted: "VALUE3",
            "KEY4[sdk=iphonesimulator*]".quoted: "VALUE4_A",
            "KEY4[sdk=iphoneos*]".quoted: "VALUE4_B",
            "KEY5": "VALUE5",
            "KEY5[sdk=iphonesimulator*]".quoted: "VALUE5_Different",
            "KEY6[sdk=watchos*]".quoted: "VALUE6",
            "IPHONEOS_DEPLOYMENT_TARGET": "12.0",
            "IPHONEOS_DEPLOYMENT_TARGET[sdk=iphonesimulator*]".quoted: "11.3.1",
            "WATCHOS_DEPLOYMENT_TARGET": "9.2",
        ]

        // Act

        let buildSettings = Generator.CalculateXcodeConfigurationBuildSettings
            .defaultCallable(
                platformBuildSettings: platformBuildSettings,
                allConditionalFiles: allConditionalFiles
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    // FIXME: test_conditionalFiles
}
