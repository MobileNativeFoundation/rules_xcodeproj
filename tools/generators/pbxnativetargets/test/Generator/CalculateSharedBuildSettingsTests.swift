import CustomDump
import OrderedCollections
import PBXProj
import ToolCommon
import XCTest

@testable import pbxnativetargets

class CalculateSharedBuildSettingsTests: XCTestCase {
    func test_labelAndCompileTargetName() {
        // Arrange

        let label: BazelLabel = "@repo//pkg:C.library_objc"

        let expectedBuildSettings = baseBuildSettings.updating([
            "BAZEL_LABEL": #""@repo//pkg:C.library_objc""#,
            "COMPILE_TARGET_NAME": "C.library_objc",
        ])

        // Act

        let buildSettings = calculateSharedBuildSettingsWithDefaults(
            label: label
        )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_launchable() {
        // Arrange

        let productType = PBXProductType.application

        let expectedBuildSettings = baseBuildSettings

        // Act

        let buildSettings = calculateSharedBuildSettingsWithDefaults(
            productType: productType
        )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_name() {
        // Arrange

        let name = "A (Disambiguated)"

        let expectedBuildSettings = baseBuildSettings.updating([
            "TARGET_NAME": #""A (Disambiguated)""#,
        ])

        // Act

        let buildSettings = calculateSharedBuildSettingsWithDefaults(name: name)

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_framework() {
        // Arrange

        let productType = PBXProductType.framework

        let expectedBuildSettings = baseBuildSettings.updating([
            "CODE_SIGNING_ALLOWED": #""$(ENABLE_PREVIEWS)""#,
        ])

        // Act

        let buildSettings = calculateSharedBuildSettingsWithDefaults(
            productType: productType
        )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_uiTest() {
        // Arrange

        let productType = PBXProductType.uiTestBundle
        let uiTestHostName = "Host (tvOS)"

        let expectedBuildSettings = baseBuildSettings.updating([
            "CODE_SIGNING_ALLOWED": "YES",
            "TEST_TARGET_NAME": #""Host (tvOS)""#,
        ])

        // Act

        let buildSettings = calculateSharedBuildSettingsWithDefaults(
            productType: productType,
            uiTestHostName: uiTestHostName
        )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_platforms() {
        // Arrange

        let platforms: OrderedSet<Platform> = [
            .tvOSSimulator,
            .macOS,
            .watchOSDevice,
        ]

        // Order is wrong, but it shows that we don't do sorting in this
        // function
        let expectedBuildSettings = baseBuildSettings.updating([
            "SDKROOT": "appletvos",
            "SUPPORTED_PLATFORMS": #""appletvsimulator macosx watchos""#,
        ])

        // Act

        let buildSettings = calculateSharedBuildSettingsWithDefaults(
            platforms: platforms
        )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_staticFramework() {
        // Arrange

        let productType = PBXProductType.staticFramework

        let expectedBuildSettings = baseBuildSettings.updating([
            "MACH_O_TYPE": "staticlib",
        ])

        // Act

        let buildSettings = calculateSharedBuildSettingsWithDefaults(
            productType: productType
        )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_supportsMacDesignedForiPhoneiPad_no() {
        // Arrange

        let platforms: OrderedSet<Platform> = [
            .iOSSimulator,
        ]

        // Order is wrong, but it shows that we don't do sorting in this
        // function
        let expectedBuildSettings = baseBuildSettings.updating([
            "SDKROOT": "iphoneos",
            "SUPPORTED_PLATFORMS": "iphonesimulator",
            "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
        ])

        // Act

        let buildSettings = calculateSharedBuildSettingsWithDefaults(
            platforms: platforms
        )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_supportsMacDesignedForiPhoneiPad_yes() {
        // Arrange

        let platforms: OrderedSet<Platform> = [
            .iOSDevice,
        ]

        // Order is wrong, but it shows that we don't do sorting in this
        // function
        let expectedBuildSettings = baseBuildSettings.updating([
            "SDKROOT": "iphoneos",
            "SUPPORTED_PLATFORMS": "iphoneos",
            "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "YES",
        ])

        // Act

        let buildSettings = calculateSharedBuildSettingsWithDefaults(
            platforms: platforms
        )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }
}

private func calculateSharedBuildSettingsWithDefaults(
        name: String = "A",
        label: BazelLabel = "@//A",
        productType: PBXProductType = .staticLibrary,
        productName: String = "product_name",
        platforms: OrderedSet<Platform> = [.macOS],
        uiTestHostName: String? = nil
) -> [BuildSetting] {
    return Generator.CalculateSharedBuildSettings.defaultCallable(
        name: name,
        label: label,
        productType: productType,
        productName: productName,
        platforms: platforms,
        uiTestHostName: uiTestHostName
    )
}

private let baseBuildSettings: [String: String] = [
    "BAZEL_LABEL": #""@//A:A""#,
    "COMPILE_TARGET_NAME": "A",
    "PRODUCT_NAME": "product_name",
    "SDKROOT": "macosx",
    "SUPPORTED_PLATFORMS": "macosx",
    "TARGET_NAME": "A",
]
