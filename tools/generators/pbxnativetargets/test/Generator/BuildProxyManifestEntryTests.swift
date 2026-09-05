import Foundation
import XCTest
@testable import pbxnativetargets

class BuildProxyManifestEntryTests: XCTestCase {
    func test_encodeJSONLines_isByteDeterministicAndSorted() throws {
        let first = BuildProxyManifestEntry(
            action: "build",
            bazelLabel: "@@//app:app",
            configuration: "Release",
            indexOutputGroups: ["bc @@//app:app ios-opt", "bi @@//app:app ios-opt"],
            outputGroup: "bp @@//app:app ios-opt",
            previewOutputGroups: [
                "bc @@//app:app ios-opt", "bp @@//app:app ios-opt", "bl @@//app:app ios-opt",
            ],
            product: .init(
                basename: "App.app",
                materialization: "copy_tree",
                name: "App",
                path: "bazel-out/App.app",
                type: "com.apple.product-type.application"
            ),
            targetID: "@@//app:app ios-opt",
            variant: .init(
                arch: "arm64",
                minimumOSVersion: "18.0",
                platform: "iphoneos"
            ),
            xcodeTargetGUID: "0000AAAAAAAA000000000001"
        )
        let second = BuildProxyManifestEntry(
            action: "build",
            bazelLabel: "@@//app:app",
            configuration: "Debug",
            indexOutputGroups: ["bc @@//app:app ios-sim-dbg", "bi @@//app:app ios-sim-dbg"],
            outputGroup: "bp @@//app:app ios-sim-dbg",
            previewOutputGroups: [
                "bc @@//app:app ios-sim-dbg", "bp @@//app:app ios-sim-dbg", "bl @@//app:app ios-sim-dbg",
            ],
            product: .init(
                basename: "App.app",
                materialization: "copy_tree",
                name: "App",
                path: "bazel-out/App.app",
                type: "com.apple.product-type.application"
            ),
            targetID: "@@//app:app ios-sim-dbg",
            variant: .init(
                arch: "arm64",
                minimumOSVersion: "18.0",
                platform: "iphonesimulator"
            ),
            xcodeTargetGUID: "0000AAAAAAAA000000000001"
        )

        let forward = try BuildProxyManifestEntry.encodeJSONLines([first, second])
        let reverse = try BuildProxyManifestEntry.encodeJSONLines([second, first])

        XCTAssertEqual(forward, reverse)
        let objects = try forward.split(separator: 0x0A).map { line in
            try XCTUnwrap(
                JSONSerialization.jsonObject(with: Data(line)) as? [String: Any]
            )
        }
        XCTAssertEqual(objects.compactMap { $0["configuration"] as? String }, ["Debug", "Release"])
        XCTAssertEqual(
            objects.first?["previewOutputGroups"] as? [String],
            [
                "bc @@//app:app ios-sim-dbg",
                "bp @@//app:app ios-sim-dbg",
                "bl @@//app:app ios-sim-dbg",
            ]
        )
    }

    func test_encodeJSONLines_omitsAbsentProductPath() throws {
        let entry = BuildProxyManifestEntry(
            action: "build",
            bazelLabel: "@@//lib",
            configuration: "Debug",
            indexOutputGroups: ["bc @@//lib macos-dbg", "bi @@//lib macos-dbg"],
            outputGroup: "bp @@//lib macos-dbg",
            previewOutputGroups: [
                "bc @@//lib macos-dbg", "bp @@//lib macos-dbg", "bl @@//lib macos-dbg",
            ],
            product: .init(
                basename: "libLib.a",
                materialization: "none",
                name: "Lib",
                path: nil,
                type: "com.apple.product-type.library.static"
            ),
            targetID: "@@//lib macos-dbg",
            variant: .init(
                arch: "arm64",
                minimumOSVersion: "14.0",
                platform: "macosx"
            ),
            xcodeTargetGUID: "0000BBBBBBBB000000000001"
        )

        let data = try BuildProxyManifestEntry.encodeJSONLines([entry])
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let product = try XCTUnwrap(object["product"] as? [String: Any])

        XCTAssertNil(product["path"])
    }
}
