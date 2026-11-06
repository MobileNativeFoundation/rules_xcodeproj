import XCTest
@testable import target_build_settings

final class SDKPathTests: XCTestCase {
    func testVersionedSDKPathsUseTheSelectedDeveloperDirectory() {
        XCTAssertEqual("__BAZEL_XCODE_SDKROOT__/usr/lib/swift".buildSettingPath(), "$(SDKROOT)/usr/lib/swift")
        XCTAssertEqual("__BAZEL_XCODE_DEVELOPER_DIR__/Platforms".buildSettingPath(), "$(DEVELOPER_DIR)/Platforms")
        for version in ["26_5_0_17F42", "26_6_0_17F113"] {
            for suffix in [
                "Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
                "Toolchains/XcodeDefault.xctoolchain/usr/lib/swift",
            ] {
                let path = "__bazel_developer_dir_\(version)/\(suffix)"
                let expected = "$(DEVELOPER_DIR)/\(suffix)"
                XCTAssertEqual(path.substituteBazelPlaceholders(), expected)
                XCTAssertEqual(path.buildSettingPath(), expected)
            }
        }
    }

    func testOtherRelativePathsAreNotSDKWorkerAliases() {
        for path in [
            "Vendor/__bazel_developer_dir_26_5_0_17F42/Platforms/Frameworks",
            "__bazel_developer_dir_26_5_0_17F42/Custom/Frameworks",
            "__bazel_developer_dir_26_5_0_17F42/../Frameworks",
            "__bazel_developer_dir_unknown/Platforms/Frameworks",
        ] {
            XCTAssertEqual(path.substituteBazelPlaceholders(), path)
            XCTAssertEqual(path.buildSettingPath(), "$(SRCROOT)/\(path)")
        }
    }
}
