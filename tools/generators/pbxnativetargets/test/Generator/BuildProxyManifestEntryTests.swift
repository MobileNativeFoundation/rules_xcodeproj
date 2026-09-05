import Foundation
import XCTest
@testable import pbxnativetargets

class BuildProxyManifestEntryTests: XCTestCase {
    func test_encodeJSONLines_isByteDeterministicAndSorted() throws {
        let first = BuildProxyManifestEntry(
            action: "build",
            bazelLabel: "@@//app:app",
            configuration: "Release",
            outputGroup: "bp @@//app:app ios-opt",
            product: .init(
                basename: "App.app",
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
            outputGroup: "bp @@//app:app ios-sim-dbg",
            product: .init(
                basename: "App.app",
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
        XCTAssertEqual(
            String(decoding: forward, as: UTF8.self),
            #"{"action":"build","bazelLabel":"@@//app:app","configuration":"Debug","outputGroup":"bp @@//app:app ios-sim-dbg","product":{"basename":"App.app","name":"App","path":"bazel-out/App.app","type":"com.apple.product-type.application"},"targetID":"@@//app:app ios-sim-dbg","variant":{"arch":"arm64","minimumOSVersion":"18.0","platform":"iphonesimulator"},"xcodeTargetGUID":"0000AAAAAAAA000000000001"}"# + "\n" +
                #"{"action":"build","bazelLabel":"@@//app:app","configuration":"Release","outputGroup":"bp @@//app:app ios-opt","product":{"basename":"App.app","name":"App","path":"bazel-out/App.app","type":"com.apple.product-type.application"},"targetID":"@@//app:app ios-opt","variant":{"arch":"arm64","minimumOSVersion":"18.0","platform":"iphoneos"},"xcodeTargetGUID":"0000AAAAAAAA000000000001"}"# + "\n"
        )
    }

    func test_encodeJSONLines_omitsAbsentProductPath() throws {
        let entry = BuildProxyManifestEntry(
            action: "build",
            bazelLabel: "@@//lib",
            configuration: "Debug",
            outputGroup: "bp @@//lib macos-dbg",
            product: .init(
                basename: "libLib.a",
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
