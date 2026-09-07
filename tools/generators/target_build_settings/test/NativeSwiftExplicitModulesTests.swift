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

}
