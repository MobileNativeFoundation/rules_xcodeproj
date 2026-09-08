import CustomDump
import PBXProj
import XCTest
@testable import pbxnativetargets

final class PlatformTargetIDBuildSettingsTests: XCTestCase {
    private let targetIDKeys = ["BAZEL_TARGET_ID", "BAZEL_COMPILE_TARGET_IDS"]

    func test_basePlatformRetainsExplicitSDKIDsInEitherInputOrder() {
        for key in targetIDKeys {
            let macOS = settings(.macOS, key: key, value: "macos-id")
            let simulator = settings(.iOSSimulator, key: key, value: "ios-id")
            for platforms in [[macOS, simulator], [simulator, macOS]] {
                XCTAssertNoDifference(values(platforms), [
                    key: platforms[0].buildSettings[0].value,
                    "\(key)[sdk=macosx*]".quoted: "macos-id",
                    "\(key)[sdk=iphonesimulator*]".quoted: "ios-id",
                ])
            }
        }
    }

    func test_equalIDsRetainEverySupportedSDKConditional() {
        for key in targetIDKeys {
            XCTAssertNoDifference(values([
                settings(.macOS, key: key, value: "shared-id"),
                settings(.iOSSimulator, key: key, value: "shared-id"),
            ]), [
                key: "shared-id",
                "\(key)[sdk=macosx*]".quoted: "shared-id",
                "\(key)[sdk=iphonesimulator*]".quoted: "shared-id",
            ])
        }
    }

    func test_singlePlatformRetainsBaseFallbackWithoutInventingOtherSDKs() {
        for key in targetIDKeys {
            XCTAssertNoDifference(values([
                settings(.macOS, key: key, value: "macos-id"),
            ]), [
                key: "macos-id",
                "\(key)[sdk=macosx*]".quoted: "macos-id",
            ])
        }
    }

    func test_missingPlatformValueStillInheritsItsDefault() {
        for key in targetIDKeys {
            XCTAssertNoDifference(values([
                settings(.macOS, key: key, value: "macos-id"),
                .init(
                    platform: .iOSSimulator,
                    conditionalFiles: [],
                    buildSettings: []
                ),
            ]), [
                "\(key)[sdk=macosx*]".quoted: "macos-id",
            ])
        }
    }

    func test_otherSettingsStillDeduplicateBaseAndEqualPlatformValues() {
        XCTAssertNoDifference(values([
            settings(.macOS, key: "OTHER_SETTING", value: "shared-value"),
            settings(.iOSSimulator, key: "OTHER_SETTING", value: "shared-value"),
        ]), ["OTHER_SETTING": "shared-value"])
    }

    private func settings(
        _ platform: Platform,
        key: String,
        value: String
    ) -> PlatformBuildSettings {
        return .init(
            platform: platform,
            conditionalFiles: [],
            buildSettings: [.init(key: key, value: value)]
        )
    }

    private func values(
        _ platformBuildSettings: [PlatformBuildSettings]
    ) -> [String: String] {
        return Generator.CalculateXcodeConfigurationBuildSettings
            .defaultCallable(
                platformBuildSettings: platformBuildSettings,
                allConditionalFiles: []
            ).asDictionary
    }
}
