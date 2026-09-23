import XCTest
@testable import target_build_settings

final class NativeSwiftProfileTests: XCTestCase {
    func testInstrumentationRequirement() async throws {
        for flag in [
            "-profile-generate", "-ir-profile-generate", "-cs-profile-generate",
            "-ir-profile-generate=/profile output", "-cs-profile-generate=/profile output",
        ] {
            let cases = flag == "-profile-generate" ? [[flag], ["-Xfrontend", flag]] : [["-Xfrontend", flag]]
            for flags in cases {
                let settings = try await settings(flags)
                XCTAssertEqual(settings["BAZEL_PREVIEW_SWIFT_PROFILE"], "YES", flags.description)
                XCTAssertTrue(try XCTUnwrap(settings["OTHER_SWIFT_FLAGS"]).contains(flag))
            }
        }
    }

    func testConsumesOptionLookingValuesOnlyOnce() async throws {
        for flags in [
            ["-I", "-I", "-profile-generate"],
            ["-Xfrontend", "-I", "-Xfrontend", "-I", "-Xfrontend", "-profile-generate"],
            ["-Xcc", "-Xfrontend", "-profile-generate"],
        ] {
            let settings = try await settings(flags)
            XCTAssertEqual(settings["BAZEL_PREVIEW_SWIFT_PROFILE"], "YES", flags.description)
        }
    }

    func testNonInstrumentationAndOptionValues() async throws {
        let cases: [[String]] = [
            [], ["-profile-coverage-mapping"], ["-profile-use=/profile.profdata"],
            ["-ir-profile-generate"], ["-cs-profile-generate"],
            ["-ir-profile-generate=/profile output"], ["-cs-profile-generate=/profile output"],
            ["-profile-sample-use=/sample.profdata"], ["-ir-profile-use=/ir.profdata"],
            ["-Xcc", "-fprofile-instr-generate"], ["-Xcc", "-profile-generate"],
            ["-Xlinker", "-profile-generate"], ["-Xllvm", "-profile-generate"],
            ["-I", "-profile-generate"], ["-F", "-profile-generate"],
            ["-D", "-profile-generate"], ["-module-link-name", "-profile-generate"],
            ["-module-name", "-profile-generate"],
            ["-import-objc-header", "-profile-generate"],
            ["-emit-objc-header-path", "-profile-generate"],
            ["-Xfrontend", "-load-plugin-executable", "-Xfrontend", "-profile-generate"],
            ["-Xfrontend", "-vfsoverlay", "-Xfrontend", "-profile-generate"],
            ["-Xfrontend", "-project-name", "-Xfrontend", "-profile-generate"],
            ["-Xfrontend", "-index-unit-output-path", "-Xfrontend", "-profile-generate"],
            ["-Xfrontend", "-I", "-D", "VALUE", "-Xfrontend", "-profile-generate"],
        ]
        for flags in cases {
            let settings = try await settings(flags)
            XCTAssertEqual(settings["BAZEL_PREVIEW_SWIFT_PROFILE"], "NO", flags.description)
        }
        for binding in ["-stats-output-dir", "-cas-path", "-save-optimization-record-path"] {
            let settings = try await settings(["-Xfrontend", binding, "-Xfrontend", "-profile-generate"])
            XCTAssertEqual(settings["BAZEL_PREVIEW_SWIFT_PROFILE"], "NO", binding)
        }
    }

    private func settings(_ flags: [String]) async throws -> [String: String] {
        let envelope = ["", "0", "0", "", "", "", "", "", "0", "", "", "", "0", "", ""]
        let result = try await Generator.Environment.default.processArgs(
            rawArguments: (envelope + ["swift_worker", "swiftc"] + flags + ["---", "---"])[...],
            generateBuildSettings: true,
            includeSelfSwiftDebugSettings: true,
            transitiveSwiftDebugSettingPaths: []
        )
        return Dictionary(uniqueKeysWithValues: result.buildSettings)
    }
}
