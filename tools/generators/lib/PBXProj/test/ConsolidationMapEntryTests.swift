import CustomDump
import XCTest

@testable import PBXProj

final class ConsolidationMapEntryTests: XCTestCase {
    func test_encodeDecode() async throws {
        // Arrange

        let input: [ConsolidationMapEntry] = [
            .init(
                key: .init(["CCCCC"]),
                label: "@//:CCCCC",
                productType: .commandLineTool,
                name: "Disambiguated 3 (Name)",
                originalProductBasename: "c",
                uiTestHostName: nil,
                subIdentifier: .init(shard: "42", hash: "18270012"),
                watchKitExtensionProductIdentifier: nil,
                dependencySubIdentifiers: [
                    .init(shard: "02", hash: "00234561"),
                    .init(shard: "79", hash: "11111111"),
                ]
            ),
            .init(
                key: .init(["@A//:a 1234", "@B//:b 4356", "DDDD"]),
                label: "@//package:a",
                productType: .uiTestBundle,
                name: "Disambiguated 2",
                originalProductBasename: "test.xctest",
                uiTestHostName: "Disambiguated 3 (Name)",
                subIdentifier: .init(shard: "01", hash: "12345678"),
                // Doesn't make sense, but testing the encoding and decoding
                watchKitExtensionProductIdentifier: .init(
                    shard: "42",
                    type: .product,
                    path: "extension.appex",
                    hash: "77777777"
                ),
                dependencySubIdentifiers: []
            ),
            .init(
                key: .init(["A", "C"]),
                label: "@repo//:C",
                productType: .staticLibrary,
                name: "Disambiguated",
                originalProductBasename: "libtest.a",
                uiTestHostName: nil,
                subIdentifier: .init(shard: "00", hash: "00000000"),
                watchKitExtensionProductIdentifier: nil,
                dependencySubIdentifiers: [
                    .init(shard: "44", hash: "00000000"),
                ]
            ),
        ]

        let tempDir = try TemporaryDirectory()
        let file = tempDir.url.appendingPathComponent("tmp", isDirectory: false)

        // Act

        try ConsolidationMapEntry.encode(input, to: file)
        let output = try await ConsolidationMapEntry.decode(from: file)

        // Assert

        XCTAssertNoDifference(output, input)
    }
}
