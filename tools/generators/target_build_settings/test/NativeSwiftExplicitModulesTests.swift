import Foundation
import XCTest
@testable import target_build_settings

final class NativeSwiftExplicitModulesTests: XCTestCase {
    private let map = "bazel-out/config/bin/control.swift-explicit-module-map.json"
    private let swift = "bazel-out/config/bin/Directory With Spaces/LocalSwift.swiftmodule"
    private let clang = "bazel-out/config/bin/local/module.modulemap"

    private var manifest: Data {
        Data("""
        [
          {"moduleName":"Foundation","isSystem":true,"isFramework":true,"modulePath":"__bazel_developer_dir_26_6_0_17F113/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/swift/Foundation.swiftmodule"},
          {"moduleName":"LocalSwift","isSystem":false,"isFramework":false,"modulePath":"\(swift)"},
          {"moduleName":"LocalClang","isSystem":false,"isFramework":false,"clangModulePath":"bazel-out/local.pcm","clangModuleMapPath":"\(clang)"}
        ]
        """.utf8)
    }

    private var args: [String] {
        ["-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
         "-Xfrontend", "-explicit-swift-module-map-file", "-Xfrontend", map.buildSettingPath().quoteIfNeeded(),
         "-Xfrontend", "-disable-implicit-swift-modules",
         "-Xfrontend", "-disable-building-interface",
         "-Xcc", "-fno-implicit-modules", "-Xcc", "-fno-implicit-module-maps"]
    }

    func testManifestOnlyGraphRestoresLocalDiscoveryAndPreservesOtherFlags() {
        let result = NativeSwiftExplicitModules.normalize(
            args, manifests: [map: manifest], preparedPaths: [swift, clang]
        )
        XCTAssertEqual(result, [
            "-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
            "-I", "'$(BAZEL_OUT)/config/bin/Directory With Spaces'", "-Xcc",
            "-fmodule-map-file=$(BAZEL_OUT)/config/bin/local/module.modulemap",
        ])
    }

    func testMissingPrivateOrImplicitLocalFileRetainsOriginal() {
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: manifest], preparedPaths: [clang]))
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: manifest], preparedPaths: [swift]))
    }

    func testMalformedAndUnownedManifestsRetainOriginal() {
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: Data("[".utf8)], preparedPaths: [swift, clang]))
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: ["other.json": manifest], preparedPaths: [swift, clang]))
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [:], preparedPaths: [swift, clang]))
    }

    func testUnknownPCMAndLocalFrameworkRetainOriginal() {
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args + ["-Xcc", "-fmodule-file=Unknown=missing.pcm"], manifests: [map: manifest], preparedPaths: [swift, clang]))
        let framework = Data("[{\"moduleName\":\"Local\",\"isSystem\":false,\"isFramework\":true,\"modulePath\":\"Local.framework/Modules/Local.swiftmodule\"}]".utf8)
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: framework], preparedPaths: [swift, clang]))
    }

    func testIncompleteForwardedOptionRetainsOriginal() {
        XCTAssertNil(NativeSwiftExplicitModules.normalize(Array(args.dropLast()), manifests: [map: manifest], preparedPaths: [swift, clang]))
    }

    func testRenamedModuleAndUnknownSystemOwnershipRetainOriginal() {
        let text = String(decoding: manifest, as: UTF8.self)
        let renamed = Data(text.replacingOccurrences(of: "\"moduleName\":\"LocalSwift\"", with: "\"moduleName\":\"Renamed\"").utf8)
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: renamed], preparedPaths: [swift, clang]))
        let unknownSystem = Data(text.replacingOccurrences(of: "__bazel_developer_dir_26_6_0_17F113/Platforms/", with: "external/custom-system/").utf8)
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: unknownSystem], preparedPaths: [swift, clang]))
    }

    func testNativeConfigurationSelectsFlagsIndependentlyOfPreviewHints() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manifestURL = directory.appendingPathComponent("control.swift-explicit-module-map.json")
        try manifest.write(to: manifestURL)
        let rawSwift = args.map { $0 == map.buildSettingPath().quoteIfNeeded() ? manifestURL.path : $0 }
        func process(owned: Bool) async throws -> ([(key: String, value: String)], [String]) {
            let envelope = ["", "0", "0", "", "", "", "", "", "0", "", "", "0"]
            let input = envelope + (owned ? [manifestURL.path] : []) + [""] + [swift, clang, ""] + ["swift_worker", "swiftc"] + rawSwift + ["---", "---"]
            let result = try await Generator.Environment.default.processArgs(
                rawArguments: input[...], generateBuildSettings: true,
                includeSelfSwiftDebugSettings: true, transitiveSwiftDebugSettingPaths: []
            )
            return (result.buildSettings, result.clangArgs)
        }
        let original = try await process(owned: false)
        let candidate = try await process(owned: true)
        XCTAssertEqual(original.1, candidate.1)
        let settings = Dictionary(uniqueKeysWithValues: candidate.0)
        XCTAssertEqual(settings["BAZEL_SWIFT_FLAGS__NO"], Dictionary(uniqueKeysWithValues: original.0)["OTHER_SWIFT_FLAGS"])
        for nativeSetting in ["", "NO", "YES"] {
        for legacy in ["", "NO", "YES"] {
            for xojit in ["", "NO", "YES"] {
                var values = settings.mapValues { $0.hasPrefix("\"") ? String($0.dropFirst().dropLast()) : $0 }
                values["BAZEL_NATIVE_PREVIEWS"] = nativeSetting
                values["ENABLE_PREVIEWS"] = legacy
                values["ENABLE_XOJIT_PREVIEWS"] = xojit
                var expanded = try XCTUnwrap(values["OTHER_SWIFT_FLAGS"])
                let regex = try NSRegularExpression(pattern: #"\$\(([^()]*)\)"#)
                for _ in 0 ..< 10 {
                    for match in regex.matches(in: expanded, range: NSRange(expanded.startIndex..., in: expanded)).reversed() {
                        let key = try String(expanded[XCTUnwrap(Range(match.range(at: 1), in: expanded))])
                        if let value = values[key] { try expanded.replaceSubrange(XCTUnwrap(Range(match.range, in: expanded)), with: value) }
                    }
                }
                let native = nativeSetting == "YES"
                XCTAssertEqual(expanded.contains("explicit-swift-module-map-file"), !native, "legacy=\(legacy), XOJIT=\(xojit)")
            }
        }
        }
    }
}
