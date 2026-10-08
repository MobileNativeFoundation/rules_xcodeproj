import Foundation
import PBXProj
import XCTest
@testable import pbxproj_prefix

class PreviewConfigurationTests: XCTestCase {
    func testToolsHaveOneConfigurationScopedOwner() throws {
        for native in [false, true] {
            let serialized = Generator.pbxProjectBuildSettings(
                config: "rules_xcodeproj",
                createBuildSettingsAttribute: CreateBuildSettingsAttribute(),
                importIndexBuildIndexstores: false,
                indexImport: "index_import",
                indexingProjectDir: "/index",
                legacyIndexImport: "legacy_index_import",
                nativePreviews: native,
                projectDir: "/execroot/main",
                resolvedRepositories: "",
                separateIndexBuildOutputBase: false,
                suppressCoverageBuild: false,
                workspace: "/workspace"
            )
            let settings = try XCTUnwrap(try PropertyListSerialization.propertyList(
                from: Data(serialized.utf8), options: [], format: nil
            ) as? [String: String])
            let toolchain = "$(DT_TOOLCHAIN_DIR)/usr/bin/"
            let integration = "$(BAZEL_INTEGRATION_DIR)/"
            for (key, realTool, stub) in [
                ("CC", "clang", "clang.sh"),
                ("CXX", "clang++", "clang.sh"),
                ("LD", "clang", "ld"),
                ("LDPLUSPLUS", "clang++", "ld"),
                ("SWIFT_EXEC", "swiftc", "swiftc"),
            ] {
                XCTAssertEqual(settings[key], native ? toolchain + realTool : integration + stub)
            }
            XCTAssertEqual(settings["LIBTOOL"], integration + (native ? "xojit/libtool" : "libtool"))
            XCTAssertEqual(settings["BAZEL_NATIVE_PREVIEWS"], native ? "YES" : "NO")
            XCTAssertEqual(settings["BAZEL_SWIFT_COMPILATION_MODE"], native ? "singlefile" : "wholemodule")
            XCTAssertEqual(settings["ENABLE_DEBUG_DYLIB"], native ? "YES" : "NO")
            XCTAssertEqual(settings["SWIFT_USE_INTEGRATED_DRIVER"], native ? "YES" : "NO")
            XCTAssertFalse(serialized.contains("ENABLE_XOJIT_PREVIEWS"))
        }
    }

    func testAliasedConfigurationsKeepDistinctSettings() {
        let partial = Generator.pbxProjectPrefixPartial(
            buildSettings: ["Debug": "{OWNER = bazel;}", "Preview With Spaces": "{OWNER = native;}"],
            compatibilityVersion: "Xcode 16.0",
            defaultXcodeConfiguration: "Debug",
            developmentRegion: "en",
            organizationName: nil,
            projectDir: "/execroot/main",
            workspace: "/workspace",
            xcodeConfigurations: ["Debug", "Preview With Spaces"]
        )
        XCTAssertTrue(partial.contains("buildSettings = {OWNER = bazel;};\n\t\t\tname = Debug;"))
        XCTAssertTrue(partial.contains("buildSettings = {OWNER = native;};\n\t\t\tname = \"Preview With Spaces\";"))
        XCTAssertTrue(partial.contains("defaultConfigurationName = Debug;"))
    }
}
