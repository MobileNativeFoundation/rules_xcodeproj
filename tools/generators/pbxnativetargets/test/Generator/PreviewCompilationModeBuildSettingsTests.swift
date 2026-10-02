import ToolCommon
import XCTest
@testable import pbxnativetargets
@testable import PBXProj

class PreviewCompilationModeBuildSettingsTests: XCTestCase {
    func test_previewPlatformsUseConfigurationScopedCompilationForWMO() async throws {
        for platform in [
            Platform.macOS,
            .iOSSimulator,
            .tvOSSimulator,
            .visionOSSimulator,
            .watchOSSimulator,
        ] {
            let buildSettings =
                try await calculatePlatformVariantBuildSettingsWithDefaults(
                    platformVariant: .mock(
                        platform: platform,
                        buildSettingsFromFile: [
                            .init(
                                key: "SWIFT_COMPILATION_MODE",
                                value: "wholemodule"
                            ),
                            .init(key: "OTHER_SETTING", value: "VALUE"),
                        ]
                    )
                )

            XCTAssertEqual(
                buildSettings.asDictionary["SWIFT_COMPILATION_MODE"],
                #""$(BAZEL_SWIFT_COMPILATION_MODE)""#,
                "platform: \(platform)"
            )
            XCTAssertEqual(
                buildSettings.asDictionary["OTHER_SETTING"],
                "VALUE",
                "platform: \(platform)"
            )
        }
    }

    func test_devicePlatformsPreserveWholeModuleCompilation() async throws {
        for platform in [
            Platform.iOSDevice,
            .tvOSDevice,
            .visionOSDevice,
            .watchOSDevice,
        ] {
            let buildSettings =
                try await calculatePlatformVariantBuildSettingsWithDefaults(
                    platformVariant: .mock(
                        platform: platform,
                        buildSettingsFromFile: [
                            .init(
                                key: "SWIFT_COMPILATION_MODE",
                                value: "wholemodule"
                            ),
                        ]
                    )
                )

            XCTAssertEqual(
                buildSettings.asDictionary["SWIFT_COMPILATION_MODE"],
                "wholemodule",
                "platform: \(platform)"
            )
        }
    }

    func test_previewPlatformsPreserveOtherCompilationModes() async throws {
        for compilationMode in ["singlefile", "unknown"] {
            let buildSettings =
                try await calculatePlatformVariantBuildSettingsWithDefaults(
                    platformVariant: .mock(
                        platform: .iOSSimulator,
                        buildSettingsFromFile: [
                            .init(
                                key: "SWIFT_COMPILATION_MODE",
                                value: compilationMode
                            ),
                        ]
                    )
                )

            XCTAssertEqual(
                buildSettings.asDictionary["SWIFT_COMPILATION_MODE"],
                compilationMode
            )
        }
    }
}
