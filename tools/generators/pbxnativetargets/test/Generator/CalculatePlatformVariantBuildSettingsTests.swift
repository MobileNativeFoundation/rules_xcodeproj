import CustomDump
import PBXProj
import ToolCommon
import XCTest

@testable import pbxnativetargets

class CalculatePlatformVariantBuildSettingsTests: XCTestCase {

    func test_base() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock()

        let expectedBuildSettings = baseBuildSettings

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    // MARK: platformVariant

    func test_arch() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock(
            arch: "x86_64"
        )

        let expectedBuildSettings = baseBuildSettings.updating([
            "ARCHS": "x86_64",
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_arch_escaped() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock(
            arch: "something-odd"
        )

        let expectedBuildSettings = baseBuildSettings.updating([
            "ARCHS": #""something-odd""#,
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_compileTargets() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock(
            compileTargetIDs: "B config A config"
        )

        let expectedBuildSettings = baseBuildSettings.updating([
            "BAZEL_COMPILE_TARGET_IDS": #""B config A config""#,
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_executableExtension() async throws {
        // Arrange

        let isBundle = false
        let originalProductBasename = "tool.so"
        let productType = PBXProductType.dynamicLibrary
        let platformVariant = Target.PlatformVariant.mock()

        let expectedBuildSettings = baseBuildSettings.updating([
            "EXECUTABLE_EXTENSION": "so",
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                isBundle: isBundle,
                originalProductBasename: originalProductBasename,
                productType: productType,
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_executableExtension_empty() async throws {
        // Arrange

        let isBundle = false
        let originalProductBasename = "tool"
        let productType = PBXProductType.dynamicLibrary
        let platformVariant = Target.PlatformVariant.mock()

        let expectedBuildSettings = baseBuildSettings.updating([
            "EXECUTABLE_EXTENSION": #""""#,
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                isBundle: isBundle,
                originalProductBasename: originalProductBasename,
                productType: productType,
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_executableName_same() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock(
            productName: "tool",
            executableName: "tool"
        )

        let expectedBuildSettings = baseBuildSettings

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_executableName_different() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock(
            productName: "tool",
            executableName: "other name"
        )

        let expectedBuildSettings = baseBuildSettings.updating([
            "EXECUTABLE_NAME": "other name".pbxProjEscaped,
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_id() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock(
            id: "ID config"
        )

        let expectedBuildSettings = baseBuildSettings.updating([
            "BAZEL_TARGET_ID": "ID config".pbxProjEscaped,
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_linkParams() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock(
            linkParams: "bazel-out/some/link.params"
        )

        let expectedBuildSettings = baseBuildSettings.updating([
            "LINK_PARAMS_FILE":
                "$(BAZEL_OUT)/some/link.params".pbxProjEscaped,
            "OTHER_LDFLAGS":
                "@$(DERIVED_FILE_DIR)/link.params".pbxProjEscaped,
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_packageBinDir() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock(
            packageBinDir: "bazel-out/package/dir"
        )

        let expectedBuildSettings = baseBuildSettings.updating([
            "BAZEL_PACKAGE_BIN_DIR": "bazel-out/package/dir".pbxProjEscaped,
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_platform() async throws {
        // Arrange

        let platformVariant = Target.PlatformVariant.mock(
            platform: .tvOSSimulator,
            osVersion: "8"
        )

        let expectedBuildSettings = noPlatformBuildSettings.updating([
            "TVOS_DEPLOYMENT_TARGET": "8.0",
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_unitTest_noTestHost() async throws {
        // Arrange

        let isBundle = true
        let originalProductBasename = "test.xctest"
        let productType = PBXProductType.unitTestBundle
        let platformVariant = Target.PlatformVariant.mock()

        let expectedBuildSettings = baseBuildSettings

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                isBundle: isBundle,
                originalProductBasename: originalProductBasename,
                productType: productType,
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_unitTest_withTestHost() async throws {
        // Arrange

        let isBundle = true
        let originalProductBasename = "test.xctest"
        let productType = PBXProductType.unitTestBundle
        let platformVariant = Target.PlatformVariant.mock(
            unitTestHost: .init(
                basename: "a/path/Host.app",
                executableName: "Executable_Name",
                packageBinDir: "some/packageBin/dir"
            )
        )

        let expectedBuildSettings = baseBuildSettings.updating([
            "TARGET_BUILD_DIR": #"""
$(BUILD_DIR)/some/packageBin/dir$(TARGET_BUILD_SUBPATH)
"""#.pbxProjEscaped,
            "TEST_HOST": #"""
$(BUILD_DIR)/some/packageBin/dir/a/path/Host.app/Executable_Name
"""#.pbxProjEscaped,
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                isBundle: isBundle,
                originalProductBasename: originalProductBasename,
                productType: productType,
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }

    func test_wrappedExtension() async throws {
        // Arrange

        let isBundle = true
        let originalProductBasename = "bundle.odd"
        let productType = PBXProductType.bundle
        let platformVariant = Target.PlatformVariant.mock()

        let expectedBuildSettings = baseBuildSettings.updating([
            "WRAPPER_EXTENSION": "odd",
        ])

        // Act

        let buildSettings =
            try await calculatePlatformVariantBuildSettingsWithDefaults(
                isBundle: isBundle,
                originalProductBasename: originalProductBasename,
                productType: productType,
                platformVariant: platformVariant
            )

        // Assert

        XCTAssertNoDifference(
            buildSettings.asDictionary,
            expectedBuildSettings
        )
    }
}

private func calculatePlatformVariantBuildSettingsWithDefaults(
    isBundle: Bool = false,
    originalProductBasename: String = "libA.a",
    productType: PBXProductType = .staticLibrary,
    platformVariant: Target.PlatformVariant
) async throws -> [PlatformVariantBuildSetting] {
    return try await Generator.CalculatePlatformVariantBuildSettings
        .defaultCallable(
            isBundle: isBundle,
            originalProductBasename: originalProductBasename,
            productType: productType,
            platformVariant: platformVariant
        )
}

private let noPlatformBuildSettings: [String: String] = [
    "ARCHS": "arm64",
    "BAZEL_PACKAGE_BIN_DIR": "some/path",
    "BAZEL_TARGET_ID": "A",
]

private let baseBuildSettings = noPlatformBuildSettings.updating([
    "ARCHS": "arm64",
    "BAZEL_PACKAGE_BIN_DIR": "some/path",
    "BAZEL_TARGET_ID": "A",
    "MACOSX_DEPLOYMENT_TARGET": "9.4.1",
])

private extension Target.PlatformVariant {
    static func mock(
        xcodeConfigurations: [String] = ["CONFIG"],
        id: TargetID = "A",
        bundleID: String? = nil,
        compileTargetIDs: String? = nil,
        packageBinDir: String = "some/path",
        outputsProductPath: String? = nil,
        productName: String = "productName",
        productBasename: String = "libA.a",
        moduleName: String = "",
        platform: Platform = .macOS,
        osVersion: SemanticVersion = "9.4.1",
        arch: String = "arm64",
        executableName: String? = nil,
        conditionalFiles: Set<BazelPath> = [],
        buildSettingsFromFile: [PlatformVariantBuildSetting] = [],
        linkParams: String? = nil,
        unitTestHost: Target.UnitTestHost? = nil,
        dSYMPathsBuildSetting: String? = nil
    ) -> Self {
        return Self(
            xcodeConfigurations: xcodeConfigurations,
            id: id,
            bundleID: bundleID,
            compileTargetIDs: compileTargetIDs,
            packageBinDir: packageBinDir,
            outputsProductPath: outputsProductPath,
            productName: productName,
            productBasename: productBasename,
            moduleName: moduleName,
            platform: platform,
            osVersion: osVersion,
            arch: arch,
            executableName: executableName,
            conditionalFiles: conditionalFiles,
            buildSettingsFromFile: buildSettingsFromFile,
            linkParams: linkParams,
            unitTestHost: unitTestHost,
            dSYMPathsBuildSetting: dSYMPathsBuildSetting
        )
    }
}

private extension Array where Element == PlatformVariantBuildSetting {
    var asDictionary: [String: String] {
        return Dictionary(uniqueKeysWithValues: map { ($0.key, $0.value) })
    }
}
