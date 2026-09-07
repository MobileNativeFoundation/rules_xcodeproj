import XCTest
@testable import target_build_settings

final class NativeSwiftOutputTests: XCTestCase {
    func testNativeOutputsDoNotWriteIntoBazelDirectories() async throws {
        let envelope = ["", "0", "0", "", "", "", "", "", "0", "", "", "0", "", ""]
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
        XCTAssertEqual(settings["SWIFT_ENABLE_EMIT_CONST_VALUES"], "NO")
    }
}
