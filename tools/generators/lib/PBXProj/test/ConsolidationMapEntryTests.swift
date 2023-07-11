import CustomDump
import XCTest

@testable import PBXProj

final class ConsolidationMapEntryTests: XCTestCase {
    func test_encodeDecode() async throws {
        // Arrange

        let input: [ConsolidationMapEntry] = [
            .init(
                key: .init(["CCCCC"]),
                name: "Disambiguated 3 (Name)",
                subIdentifier: .init(shard: "42", hash: "18270012"),
                dependencySubIdentifiers: [
                    .init(shard: "02", hash: "00234561"),
                    .init(shard: "79", hash: "11111111"),
                ]
            ),
            .init(
                key: .init(["@A//:a 1234", "@B//:b 4356", "DDDD"]),
                name: "Disambiguated 2 (Name)",
                subIdentifier: .init(shard: "01", hash: "12345678"),
                dependencySubIdentifiers: []
            ),
            .init(
                key: .init(["A", "C"]),
                name: "Disambiguated (Name)",
                subIdentifier: .init(shard: "00", hash: "00000000"),
                dependencySubIdentifiers: [
                    .init(shard: "44", hash: "00000000"),
                ]
            ),
        ]

        let tempDir = try TemporaryDirectory()
        let file = tempDir.url.appendingPathComponent("tmp", isDirectory: false)

        // Act

        try ConsolidationMapEntry.encode(entires: input, to: file)
        let output = try await ConsolidationMapEntry.decode(from: file)

        // Assert

        XCTAssertNoDifference(output, input)
    }
}

class TemporaryDirectory {
    let url: URL

    /// Creates a new temporary directory.
    ///
    /// The directory is recursively deleted when this object deallocates.
    init() throws {
        url = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: FileManager.default.temporaryDirectory,
            create: true
        )
    }

    deinit {
        _ = try? FileManager.default.removeItem(at: url)
    }
}
