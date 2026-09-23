import XCTest
@testable import target_build_settings

final class NativeSwiftOutputTests: XCTestCase {
    func testNativeModuleEmissionKeepsXcodesSourceInfoOutput() async throws {
        let envelope = ["", "0", "0", "", "", "", "", "", "0", "", "", "", "", "0", "", ""]
        for suppression in [["-avoid-emit-module-source-info"], ["-Xfrontend", "-avoid-emit-module-source-info"]] {
            let flags = suppression + ["-DKEEP"]
            let result = try await Generator.Environment.default.processArgs(
                rawArguments: (envelope + ["swift_worker", "swiftc"] + flags + ["---", "---"])[...],
                generateBuildSettings: true,
                includeSelfSwiftDebugSettings: true,
                transitiveSwiftDebugSettingPaths: []
            )
            let settings = Dictionary(uniqueKeysWithValues: result.buildSettings)
            let ordinary = try XCTUnwrap(settings["BAZEL_SWIFT_FLAGS__NO"])
            let native = try XCTUnwrap(settings["BAZEL_SWIFT_FLAGS__YES"])
            XCTAssertTrue(ordinary.contains(suppression.joined(separator: " ")))
            XCTAssertEqual(settings["BAZEL_SWIFT_FLAGS__"], ordinary)
            XCTAssertFalse(native.contains("-avoid-emit-module-source-info"))
            XCTAssertFalse(native.contains("-Xfrontend"))
            XCTAssertTrue(native.contains("-DKEEP"))
            XCTAssertNil(settings["HEADER_SEARCH_PATHS"])
            XCTAssertNil(settings["USER_HEADER_SEARCH_PATHS"])
        }
    }

    func testNativeOutputsDoNotWriteIntoBazelDirectories() async throws {
        let envelope = ["", "0", "0", "", "", "", "", "", "0", "", "", "", "", "0", "", ""]
        let flags = [
            "-emit-objc-header-path", "bazel-out/config/bin/Custom-Swift.h",
            "-emit-const-values-path", "bazel-out/config/bin/Values.swiftconstvalues",
            "-DKEEP",
        ]
        let result = try await Generator.Environment.default.processArgs(
            rawArguments: (envelope + ["swift_worker", "swiftc"] + flags + ["---", "---"])[...],
            generateBuildSettings: true,
            includeSelfSwiftDebugSettings: true,
            transitiveSwiftDebugSettingPaths: []
        )
        let settings = Dictionary(uniqueKeysWithValues: result.buildSettings)
        let ordinary = try XCTUnwrap(settings["BAZEL_SWIFT_FLAGS__NO"])
        let native = try XCTUnwrap(settings["BAZEL_SWIFT_FLAGS__YES"])
        XCTAssertTrue(ordinary.contains("-emit-objc-header-path"))
        XCTAssertTrue(ordinary.contains("-emit-const-values-path"))
        XCTAssertFalse(native.contains("-emit-objc-header-path"))
        XCTAssertFalse(native.contains("-emit-const-values-path"))
        XCTAssertFalse(native.contains("bazel-out/config/bin"))
        XCTAssertTrue(native.contains("-DKEEP"))
        XCTAssertEqual(settings["BAZEL_SWIFT_HEADER__YES"], "\"Custom-Swift.h\"")
        XCTAssertEqual(settings["BAZEL_SWIFT_HEADER__NO"], "\"\"")
        XCTAssertEqual(settings["BAZEL_SWIFT_HEADER__"], "\"\"")
        for key in ["HEADER_SEARCH_PATHS", "USER_HEADER_SEARCH_PATHS"] {
            XCTAssertEqual(settings[key], "$(BAZEL_SWIFT_HEADER_SEARCH_PATHS__$(BAZEL_NATIVE_PREVIEWS)) $(inherited)".pbxProjEscaped)
        }
        XCTAssertEqual(settings["BAZEL_SWIFT_HEADER_SEARCH_PATHS__YES"], "\"$(DERIVED_SOURCES_DIR)\"".pbxProjEscaped)
        XCTAssertEqual(settings["BAZEL_SWIFT_HEADER_SEARCH_PATHS__NO"], "\"\"")
        XCTAssertEqual(settings["BAZEL_SWIFT_HEADER_SEARCH_PATHS__"], "\"\"")
        XCTAssertEqual(settings["SWIFT_ENABLE_EMIT_CONST_VALUES"], "NO")
    }
}
