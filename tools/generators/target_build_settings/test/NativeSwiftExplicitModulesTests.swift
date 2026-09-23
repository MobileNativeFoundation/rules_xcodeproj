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

    func testOwnedTextualClangMapWithoutPrecompiledModule() {
        // rules_swift 3.5 emits textual Clang entries without a PCM path.
        let data = Data("""
        [
          {"moduleName":"LocalSwift","modulePath":"\(swift)"},
          {"moduleName":"LocalClang","isFramework":false,"clangModuleMapPath":"\(clang)"}
        ]
        """.utf8)
        XCTAssertEqual(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [swift, clang]), [
            "-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
            "-I", "'$(BAZEL_OUT)/config/bin/Directory With Spaces'", "-Xcc",
            "-fmodule-map-file=$(BAZEL_OUT)/config/bin/local/module.modulemap",
        ])
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [swift]))
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args + ["-Xcc", "-fmodule-file=LocalClang=unknown.pcm"], manifests: [map: data], preparedPaths: [swift, clang]))
    }

    func testMixedModuleRequiresBothPreparedSwiftAndClangImports() {
        // mixed_language_library publishes both imports in a single record.
        for pcm in ["", ",\"clangModulePath\":\"bazel-out/mixed.pcm\""] {
            let data = Data("""
            [{"moduleName":"LocalSwift","modulePath":"\(swift)","clangModuleMapPath":"\(clang)"\(pcm)}]
            """.utf8)
            let forwarded = pcm.isEmpty ? args : args + ["-Xcc", "-fmodule-file=LocalSwift=bazel-out/mixed.pcm"]
            XCTAssertEqual(NativeSwiftExplicitModules.normalize(forwarded, manifests: [map: data], preparedPaths: [swift, clang]), [
                "-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
                "-I", "'$(BAZEL_OUT)/config/bin/Directory With Spaces'", "-Xcc",
                "-fmodule-map-file=$(BAZEL_OUT)/config/bin/local/module.modulemap",
            ])
            for incomplete: Set<String> in [[], [swift], [clang]] {
                XCTAssertNil(NativeSwiftExplicitModules.normalize(forwarded, manifests: [map: data], preparedPaths: incomplete))
            }
            XCTAssertNil(NativeSwiftExplicitModules.normalize(forwarded + ["-Xcc", "-fmodule-file=Unknown=other.pcm"], manifests: [map: data], preparedPaths: [swift, clang]))
        }
    }

    func testMixedModuleCannotHideAnIncompleteClangImport() {
        for fields in [
            "\"modulePath\":\"\(swift)\",\"clangModulePath\":\"bazel-out/mixed.pcm\"",
            "\"isSystem\":true,\"modulePath\":\"__BAZEL_XCODE_SDKROOT__/usr/lib/swift/LocalSwift.swiftmodule\",\"clangModuleMapPath\":\"unowned.modulemap\"",
            "\"isSystem\":true,\"modulePath\":\"\(swift)\",\"clangModuleMapPath\":\"\(clang)\"",
            "\"isBridgingHeaderDependency\":true,\"modulePath\":\"\(swift)\",\"clangModuleMapPath\":\"\(clang)\"",
            "\"isFramework\":true,\"modulePath\":\"\(swift)\",\"clangModuleMapPath\":\"\(clang)\"",
            "\"isSystem\":false",
        ] {
            let data = Data("[{\"moduleName\":\"LocalSwift\",\(fields)}]".utf8)
            XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [swift, clang]), fields)
        }
    }

    func testMixedFrameworkPreservesFrameworkDiscovery() {
        let swift = "Mixed.framework/Modules/Mixed.swiftmodule/arm64.swiftmodule"
        let clang = "Mixed.framework/Modules/module.modulemap"
        let data = Data("""
        [{"moduleName":"Mixed","isFramework":true,"modulePath":"\(swift)","clangModuleMapPath":"\(clang)"}]
        """.utf8)
        XCTAssertEqual(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [swift, clang]), [
            "-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
            "-F", "$(PROJECT_DIR)", "-Xcc", "-fmodule-map-file=$(SRCROOT)/Mixed.framework/Modules/module.modulemap",
        ])
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

    func testOwnedNamedAndUnnamedPCMBindingsAreRemoved() throws {
        let expected = try XCTUnwrap(NativeSwiftExplicitModules.normalize(
            args, manifests: [map: manifest], preparedPaths: [swift, clang]
        ))
        for path in ["bazel-out/local.pcm", "$(BAZEL_OUT)/local.pcm"] {
            for binding in ["-fmodule-file=LocalClang=\(path)", "-fmodule-file=\(path)"] {
                XCTAssertEqual(NativeSwiftExplicitModules.normalize(
                    args + ["-Xcc", binding], manifests: [map: manifest], preparedPaths: [swift, clang]
                ), expected, binding)
            }
            XCTAssertNil(NativeSwiftExplicitModules.normalize(
                args + ["-Xcc", "-fmodule-file=Other=\(path)"],
                manifests: [map: manifest], preparedPaths: [swift, clang]
            ), path)
        }
    }

    func testBridgingDependencyMarkerRetainsOriginal() throws {
        let expected = try XCTUnwrap(NativeSwiftExplicitModules.normalize(
            args, manifests: [map: manifest], preparedPaths: [swift, clang]
        ))
        for marker in [false, true] {
            let data = Data(String(decoding: manifest, as: UTF8.self).replacingOccurrences(
                of: "\"moduleName\":\"LocalClang\"",
                with: "\"moduleName\":\"LocalClang\",\"isBridgingHeaderDependency\":\(marker)"
            ).utf8)
            let result = NativeSwiftExplicitModules.normalize(
                args, manifests: [map: data], preparedPaths: [swift, clang]
            )
            if marker {
                XCTAssertNil(result)
            } else {
                XCTAssertEqual(result, expected)
            }
        }
    }

    func testOwnedSDKAliasesRestoreNativeSystemDiscovery() {
        for root in [
            "__BAZEL_XCODE_SDKROOT__",
            "__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk",
            "__BAZEL_XCODE_DEVELOPER_DIR__/Toolchains/XcodeDefault.xctoolchain",
            "__bazel_developer_dir_26_5_0_17F42/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk",
            "__bazel_developer_dir_26_6_0_17F113/Toolchains/XcodeDefault.xctoolchain",
        ] {
            let systemMap = root + "/usr/include/module.modulemap"
            let data = Data("""
            [
              {"moduleName":"Foundation","isSystem":true,"modulePath":"\(root)/usr/lib/swift/Foundation.swiftmodule","clangModuleMapPath":"\(systemMap)"},
              {"moduleName":"Darwin","isSystem":true,"clangModulePath":"bazel-out/darwin.pcm","clangModuleMapPath":"\(systemMap)"}
            ]
            """.utf8)
            let forwarded = args + [
                "-Xcc", "-fmodule-file=Darwin=bazel-out/darwin.pcm",
                "-Xcc", ("-fmodule-map-file=" + systemMap.buildSettingPath()).quoteIfNeeded(),
            ]
            XCTAssertEqual(NativeSwiftExplicitModules.normalize(
                forwarded, manifests: [map: data], preparedPaths: []
            ), ["-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module"], root)
        }
    }

    func testIncompleteForwardedOptionRetainsOriginal() {
        XCTAssertNil(NativeSwiftExplicitModules.normalize(Array(args.dropLast()), manifests: [map: manifest], preparedPaths: [swift, clang]))
    }

    func testGeneratedSystemModulesRequirePreparedFiles() {
        let generated = "bazel-out/config/bin/external/system_sdk/iPhoneSimulator_Testing_outs/Testing.swiftmodule"
        let systemMap = "__BAZEL_XCODE_SDKROOT__/usr/include/module.modulemap"
        let data = Data("""
        [
          {"moduleName":"Testing","isSystem":true,"isFramework":true,"modulePath":"\(generated)"},
          {"moduleName":"Darwin","isSystem":true,"clangModulePath":"bazel-out/darwin.pcm","clangModuleMapPath":"\(systemMap)"}
        ]
        """.utf8)
        XCTAssertEqual(NativeSwiftExplicitModules.normalize(
            args + ["-Xcc", "-fmodule-file=Darwin=bazel-out/darwin.pcm"],
            manifests: [map: data], preparedPaths: [generated]
        ), [
            "-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
        ])
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: []))
        let renamed = Data(String(decoding: data, as: UTF8.self).replacingOccurrences(
            of: "Testing.swiftmodule", with: "Other.swiftmodule"
        ).utf8)
        XCTAssertNil(NativeSwiftExplicitModules.normalize(
            args, manifests: [map: renamed], preparedPaths: [generated.replacingOccurrences(of: "Testing.swiftmodule", with: "Other.swiftmodule")]
        ))
        for unsupported in ["Imports/Testing.swiftmodule", "bazel-out/config/Testing.swiftmodule/arm64.swiftmodule"] {
            let other = Data(String(decoding: data, as: UTF8.self).replacingOccurrences(of: generated, with: unsupported).utf8)
            XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: other], preparedPaths: [unsupported]))
        }
    }

    func testOwnedBinaryFrameworkAndArchitectureDirectoryImports() {
        let framework = "BinaryKit.framework/Modules/module.modulemap"
        let binary = "BinaryKit.framework/Modules/BinaryKit.swiftmodule/arm64-apple-ios-simulator.swiftmodule"
        let xcframework = "Vendor/ArchiveKit.xcframework/ios-arm64-simulator/ArchiveKit.framework/Modules/module.modulemap"
        let directory = "Imports/DirectoryKit.swiftmodule/arm64-apple-ios-simulator.swiftmodule"
        let data = Data("""
        [
          {"moduleName":"BinaryKit","isFramework":false,"clangModulePath":"bazel-out/binary.pcm","clangModuleMapPath":"\(framework)"},
          {"moduleName":"BinaryKit","modulePath":"\(binary)"},
          {"moduleName":"ArchiveKit","isFramework":false,"clangModulePath":"bazel-out/archive.pcm","clangModuleMapPath":"\(xcframework)"},
          {"moduleName":"DirectoryKit","modulePath":"\(directory)"}
        ]
        """.utf8)
        let result = NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [framework, binary, xcframework, directory])
        XCTAssertEqual(result, [
            "-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
            "-F", "$(PROJECT_DIR)", "-Xcc", "-fmodule-map-file=$(SRCROOT)/BinaryKit.framework/Modules/module.modulemap",
            "-F", "$(SRCROOT)/Vendor/ArchiveKit.xcframework/ios-arm64-simulator",
            "-Xcc", "-fmodule-map-file=$(SRCROOT)/Vendor/ArchiveKit.xcframework/ios-arm64-simulator/ArchiveKit.framework/Modules/module.modulemap",
            "-I", "$(SRCROOT)/Imports",
        ])
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [framework, xcframework, directory]))
    }

    func testOwnedPrivateFrameworkMapUsesItsPublicFrameworkDirectory() {
        let publicMap = "Vendor/PrivateKit.framework/Modules/module.modulemap"
        let privateMap = "Vendor/PrivateKit.framework/Modules/module.private.modulemap"
        let data = Data("""
        [
          {"moduleName":"PrivateKit","isFramework":true,"clangModulePath":"bazel-out/public.pcm","clangModuleMapPath":"\(publicMap)"},
          {"moduleName":"PrivateKit_Private","isFramework":true,"clangModulePath":"bazel-out/private.pcm","clangModuleMapPath":"\(privateMap)"}
        ]
        """.utf8)
        let forwarded = args + [
            "-Xcc", "-fmodule-file=PrivateKit_Private=bazel-out/private.pcm",
        ]
        XCTAssertEqual(NativeSwiftExplicitModules.normalize(forwarded, manifests: [map: data], preparedPaths: [publicMap, privateMap]), [
            "-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
            "-F", "$(SRCROOT)/Vendor",
            "-Xcc", "-fmodule-map-file=$(SRCROOT)/Vendor/PrivateKit.framework/Modules/module.modulemap",
            "-Xcc", "-fmodule-map-file=$(SRCROOT)/Vendor/PrivateKit.framework/Modules/module.private.modulemap",
        ])
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [publicMap]))
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [privateMap]))
    }

    func testMismatchedPrivateFrameworkMapNamesAndLayoutsRetainOriginal() {
        for (module, path) in [
            ("_Private", ".framework/Modules/module.private.modulemap"),
            ("PrivateKit", "PrivateKit.framework/Modules/module.private.modulemap"),
            ("Other_Private", "PrivateKit.framework/Modules/module.private.modulemap"),
            ("PrivateKit_Private_Private", "PrivateKit.framework/Modules/module.private.modulemap"),
            ("PrivateKit_Private", "PrivateKit.framework/Modules/module.modulemap"),
            ("PrivateKit_Private", "PrivateKit.framework/Modules/private.modulemap"),
            ("PrivateKit_Private", "PrivateKit.framework/Other/module.private.modulemap"),
            ("PrivateKit_Private", "PrivateKit.xcframework/Modules/module.private.modulemap"),
        ] {
            let data = Data("""
            [{"moduleName":"\(module)","isFramework":true,"clangModuleMapPath":"\(path)"}]
            """.utf8)
            XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [path]), path)
        }
    }

    func testPrivateSuffixDoesNotRenameOrdinarySwiftFrameworkModules() {
        let path = "Vendor/Kit_Private.framework/Modules/Kit_Private.swiftmodule/arm64.swiftmodule"
        let data = Data("""
        [{"moduleName":"Kit_Private","isFramework":true,"modulePath":"\(path)"}]
        """.utf8)
        XCTAssertEqual(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [path]), [
            "-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
            "-F", "$(SRCROOT)/Vendor",
        ])
        let other = path.replacingOccurrences(of: "Kit_Private.framework", with: "Kit.framework")
        let renamed = Data(String(decoding: data, as: UTF8.self).replacingOccurrences(of: path, with: other).utf8)
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: renamed], preparedPaths: [other]))
    }

    func testUnfamiliarBinaryLayoutsRetainOriginal() {
        for path in ["Other.swiftmodule/arm64.swiftmodule", "Kit.framework/Other/Kit.swiftmodule/arm64.swiftmodule", "Kit.xcframework/Kit.swiftmodule/arm64.swiftmodule"] {
            let data = Data("[{\"moduleName\":\"Kit\",\"modulePath\":\"\(path)\"}]".utf8)
            XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [path]), path)
        }
    }

    func testOwnedCompiledFrameworkInterfaceUsesFlatSearchPath() {
        let binary = "bazel-out/config/bin/binary_outs/BinaryKit.swiftmodule"
        let framework = "BinaryKit.framework/Modules/module.modulemap"
        let data = Data("""
        [
          {"moduleName":"BinaryKit","isFramework":true,"modulePath":"\(binary)"},
          {"moduleName":"BinaryKit","isFramework":true,"clangModulePath":"bazel-out/binary.pcm","clangModuleMapPath":"\(framework)"}
        ]
        """.utf8)
        XCTAssertEqual(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [binary, framework]), [
            "-DKEEP", "-Xfrontend", "-load-plugin-executable", "-Xfrontend", "plugin#Module",
            "-I", "$(BAZEL_OUT)/config/bin/binary_outs",
            "-F", "$(PROJECT_DIR)", "-Xcc", "-fmodule-map-file=$(SRCROOT)/BinaryKit.framework/Modules/module.modulemap",
        ])
        XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [framework]))
        for unsupported in ["Imports/BinaryKit.swiftmodule", "bazel-out/config/BinaryKit.swiftmodule/arm64.swiftmodule"] {
            let other = Data(String(decoding: data, as: UTF8.self).replacingOccurrences(of: binary, with: unsupported).utf8)
            XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: other], preparedPaths: [unsupported, framework]))
        }
    }

    func testUnsupportedForwardingAndCustomSDKPathsRetainOriginal() {
        for extra in [["-Xcc=-fmodule-file=Unknown=unknown.pcm"], ["-Xfrontend=-disable-implicit-swift-modules"], ["-explicit-swift-module-map-file", "unknown.json"]] {
            XCTAssertNil(NativeSwiftExplicitModules.normalize(args + extra, manifests: [map: manifest], preparedPaths: [swift, clang]))
        }
        let text = String(decoding: manifest, as: UTF8.self)
        for sdk in ["/Custom/SDK", "external/vendor-sdk", "__BAZEL_XCODE_SDKROOT__/../Other.sdk"] {
            let data = Data(text.replacingOccurrences(of: "__bazel_developer_dir_26_6_0_17F113", with: sdk).utf8)
            XCTAssertNil(NativeSwiftExplicitModules.normalize(args, manifests: [map: data], preparedPaths: [swift, clang]))
        }
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
            + ["-emit-const-values-path", "bazel-out/config/bin/values.json", "-avoid-emit-module-source-info"]
        func process(owned: Bool) async throws -> ([(key: String, value: String)], [String]) {
            let envelope = ["", "0", "0", "", "", "", "", "", "0", "", "", "", "", "0"]
            var input = envelope
            if owned { input.append(manifestURL.path) }
            input.append(contentsOf: ["", swift, clang, "", "swift_worker", "swiftc"])
            input.append(contentsOf: rawSwift)
            input.append(contentsOf: ["---", "---"])
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
        let originalSettings = Dictionary(uniqueKeysWithValues: original.0)
        XCTAssertNil(originalSettings["BAZEL_INDEX_SWIFT_FLAGS__YES"])
        XCTAssertEqual(settings["BAZEL_INDEX_SWIFT_FLAGS__NO"], originalSettings["BAZEL_SWIFT_FLAGS__NO"])
        XCTAssertEqual(settings["BAZEL_INDEX_SWIFT_FLAGS__"], settings["BAZEL_INDEX_SWIFT_FLAGS__NO"])
        XCTAssertTrue(try XCTUnwrap(settings["BAZEL_INDEX_SWIFT_FLAGS__YES"]).contains("-emit-const-values-path"))
        XCTAssertFalse(try XCTUnwrap(settings["BAZEL_SWIFT_FLAGS__YES"]).contains("-emit-const-values-path"))
        for nativeSetting in ["", "NO", "YES"] {
            for indexArena in ["", "NO", "YES"] {
                for legacy in ["", "NO", "YES"] {
                    for xojit in ["", "NO", "YES"] {
                        var values = settings.mapValues { $0.hasPrefix("\"") ? String($0.dropFirst().dropLast()) : $0 }
                        values["BAZEL_NATIVE_PREVIEWS"] = nativeSetting
                        values["INDEX_ENABLE_BUILD_ARENA"] = indexArena
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
                        let nativeImports = nativeSetting == "YES" || indexArena == "YES"
                        XCTAssertEqual(expanded.contains("explicit-swift-module-map-file"), !nativeImports, "native=\(nativeSetting), index=\(indexArena), legacy=\(legacy), XOJIT=\(xojit)")
                        XCTAssertEqual(expanded.contains("-emit-const-values-path"), nativeSetting != "YES")
                        XCTAssertEqual(expanded.contains("-avoid-emit-module-source-info"), nativeSetting != "YES")
                        XCTAssertEqual(expanded.contains("bazel-out/config/bin/values.json"), nativeSetting != "YES")
                        if nativeImports {
                            XCTAssertTrue(expanded.contains("-I '$(BAZEL_OUT)/config/bin/Directory With Spaces'"))
                            XCTAssertTrue(expanded.contains("-Xcc -fmodule-map-file=$(BAZEL_OUT)/config/bin/local/module.modulemap"))
                        } else {
                            let raw = try XCTUnwrap(originalSettings["BAZEL_SWIFT_FLAGS__NO"])
                            XCTAssertEqual(expanded, raw.hasPrefix("\"") ? String(raw.dropFirst().dropLast()) : raw)
                        }
                    }
                }
            }
        }
    }
}
