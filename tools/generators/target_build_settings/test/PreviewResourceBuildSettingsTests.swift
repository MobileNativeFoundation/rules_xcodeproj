import XCTest
@testable import target_build_settings

final class PreviewResourceBuildSettingsTests: XCTestCase {
    func test_resourceBundlePathsAreEscapedAndKeepFollowingArgumentsAligned() async throws {
        let paths = #""$(BAZEL_OUT)/First.bundle" "$(BAZEL_OUT)/Bundle With Spaces.bundle""#

        let settings = try await buildSettings(resourceBundlePaths: paths)

        XCTAssertEqual(
            settings["PREVIEW_RESOURCE_BUNDLE_PATHS"],
            #""\"$(BAZEL_OUT)/First.bundle\" \"$(BAZEL_OUT)/Bundle With Spaces.bundle\"""#
        )
        XCTAssertEqual(
            settings["PREVIEWS_SWIFT_INCLUDE__YES"],
            #""-I$(BAZEL_OUT)/preview-includes""#
        )
    }

    func test_emptyResourceBundlePathsOmitSetting() async throws {
        let settings = try await buildSettings(resourceBundlePaths: "")

        XCTAssertNil(settings["PREVIEW_RESOURCE_BUNDLE_PATHS"])
        XCTAssertNotNil(settings["PREVIEWS_SWIFT_INCLUDE__YES"])
    }

    func test_resourcesAreEmittedWithoutASwiftCompileAction() async throws {
        let settings = try await buildSettings(
            resourceBundlePaths: #""$(BAZEL_OUT)/AppResources.bundle""#,
            swiftArguments: []
        )
        XCTAssertNotNil(settings["PREVIEW_RESOURCE_BUNDLE_PATHS"])
        XCTAssertNil(settings["OTHER_SWIFT_FLAGS"])
    }

    func test_nativeFrameworkPathsUseXcodeProductsOnlyInNativeMode() async throws {
        let focused = #""$(BAZEL_OUT)/Focused.framework""#
        let imported = #""$(SRCROOT)/Imported With Spaces.framework""#
        let all = focused + " " + imported
        let native = #""$(BUILD_DIR)/other-package/Focused.framework" "# + imported
        let settings = try await buildSettings(
            resourceBundlePaths: "", frameworkPaths: all,
            nativeFrameworkPaths: native
        )
        XCTAssertEqual(settings["PREVIEW_FRAMEWORK_PATHS"], "$(PREVIEW_FRAMEWORK_PATHS__$(BAZEL_NATIVE_PREVIEWS))".pbxProjEscaped)
        XCTAssertEqual(settings["PREVIEW_FRAMEWORK_PATHS__"], all.pbxProjEscaped)
        XCTAssertEqual(settings["PREVIEW_FRAMEWORK_PATHS__NO"], all.pbxProjEscaped)
        XCTAssertEqual(settings["PREVIEW_FRAMEWORK_PATHS__YES"], native.pbxProjEscaped)
    }

    func test_singleFocusedFrameworkKeepsNativeProductPath() async throws {
        let paths = #""$(BAZEL_OUT)/Focused.framework""#
        let native = #""$(BUILD_DIR)/other-package/Focused.framework""#
        let settings = try await buildSettings(
            resourceBundlePaths: "", frameworkPaths: paths,
            nativeFrameworkPaths: native
        )
        XCTAssertEqual(settings["PREVIEW_FRAMEWORK_PATHS__YES"], native.pbxProjEscaped)
        XCTAssertEqual(settings["PREVIEW_FRAMEWORK_PATHS__NO"], paths.pbxProjEscaped)
    }

    func test_unfocusedFrameworksKeepExistingSetting() async throws {
        let paths = #""$(BAZEL_OUT)/Unfocused.framework""#
        let settings = try await buildSettings(
            resourceBundlePaths: "", frameworkPaths: paths,
            nativeFrameworkPaths: paths
        )
        XCTAssertEqual(settings["PREVIEW_FRAMEWORK_PATHS"], paths.pbxProjEscaped)
        XCTAssertNil(settings["PREVIEW_FRAMEWORK_PATHS__YES"])
    }

    private func buildSettings(
        resourceBundlePaths: String,
        frameworkPaths: String = "",
        nativeFrameworkPaths: String = "",
        swiftArguments: [String] = ["swift_worker", "swiftc", "-Onone"]
    ) async throws -> [String: String] {
        let arguments = [
            "", // device-family
            "false", // extension-safe
            "false", // generates-dsyms
            "", // info-plist
            "", // entitlements
            "", // certificate-name
            "", // provisioning-profile-name
            "", // team-id
            "false", // provisioning-profile-is-xcode-managed
            frameworkPaths,
            nativeFrameworkPaths,
            resourceBundlePaths,
            "bazel-out/preview-includes",
            "false", // separate-index-build-output-base
            "", // Swift explicit-module manifest paths
            "", // prepared local Swift import paths
        ] + swiftArguments + [
            "---",
            "---", // no C arguments
            "---", // no C++ arguments
        ]
        let result = try await Generator.Environment.default.processArgs(
            rawArguments: arguments[...],
            generateBuildSettings: true,
            includeSelfSwiftDebugSettings: true,
            transitiveSwiftDebugSettingPaths: []
        )
        return Dictionary(uniqueKeysWithValues: result.buildSettings)
    }
}
