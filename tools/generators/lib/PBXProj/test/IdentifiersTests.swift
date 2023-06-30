import CustomDump
import XCTest

@testable import PBXProj

final class IdentifiersTests: XCTestCase {

    // MARK: - FilesAndGroups.element

    // MARK: hashCache

    func test_filesAndGroups_element_hashCache_noCollision() {
        // Arrange

        var hashCache: Set<String> = []
        let path = "a/path/to/a/file"
        let type: Identifiers.FilesAndGroups.ElementType = .fileReference

        let expectedIdentifier = #"""
FE9127BCB9F1C1C990ADB87F /* a/path/to/a/file */
"""#
        let expectedModifiedHashCache: Set<String> = [
            "9127BCB9F1C1C990ADB87F",
        ]

        // Act

        let identifier = Identifiers.FilesAndGroups.element(
            path,
            type: type,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(identifier, expectedIdentifier)
        XCTAssertNoDifference(hashCache, expectedModifiedHashCache)
    }

    func test_filesAndGroups_element_hashCache_collision() {
        // Arrange

        var hashCache: Set<String> = [
            "9127BCB9F1C1C990ADB87F",
        ]
        let path = "a/path/to/a/file"
        let type: Identifiers.FilesAndGroups.ElementType = .fileReference

        let expectedIdentifier = #"""
FEC218EE063FFEACFDC4CCBF /* a/path/to/a/file */
"""#
        let expectedModifiedHashCache: Set<String> = [
            // Original
            "9127BCB9F1C1C990ADB87F",

            // Added
            "C218EE063FFEACFDC4CCBF",
        ]

        // Act

        let identifier = Identifiers.FilesAndGroups.element(
            path,
            type: type,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(identifier, expectedIdentifier)
        XCTAssertNoDifference(hashCache, expectedModifiedHashCache)
    }

    func test_filesAndGroups_element_hashCache_multipleCollisions() {
        // Arrange

        var hashCache: Set<String> = [
            "9127BCB9F1C1C990ADB87F",
            "C218EE063FFEACFDC4CCBF",
            "C86DD0F5DCF552BEABF334",
        ]
        let path = "a/path/to/a/file"
        let type: Identifiers.FilesAndGroups.ElementType = .fileReference

        let expectedIdentifier = #"""
FED9F54B134D73636F095974 /* a/path/to/a/file */
"""#
        let expectedModifiedHashCache: Set<String> = [
            // Original
            "9127BCB9F1C1C990ADB87F", // collision 1
            "C218EE063FFEACFDC4CCBF", // collision 2
            "C86DD0F5DCF552BEABF334", // collision 3

            // Added
            "D9F54B134D73636F095974",
        ]

        // Act

        let identifier = Identifiers.FilesAndGroups.element(
            path,
            type: type,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(identifier, expectedIdentifier)
        XCTAssertNoDifference(hashCache, expectedModifiedHashCache)
    }

    // MARK: type

    func test_filesAndGroups_element_type_fileReference() {
        // Arrange

        var hashCache: Set<String> = []
        let path = "a/path/to/an/element"
        let type: Identifiers.FilesAndGroups.ElementType = .fileReference

        let expectedIdentifier = #"""
FEF8A9154DBAF0B6DF9804E2 /* a/path/to/an/element */
"""#

        // Act

        let identifier = Identifiers.FilesAndGroups.element(
            path,
            type: type,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(identifier, expectedIdentifier)
    }

    func test_filesAndGroups_element_type_group() {
        // Arrange

        var hashCache: Set<String> = []
        let path = "a/path/to/an/element"
        let type: Identifiers.FilesAndGroups.ElementType = .group

        let expectedIdentifier = #"""
FE76BD00D1EAF8EE030DB890 /* a/path/to/an/element */
"""#

        // Act

        let identifier = Identifiers.FilesAndGroups.element(
            path,
            type: type,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(identifier, expectedIdentifier)
    }

    func test_filesAndGroups_element_type_localized() {
        // Arrange

        var hashCache: Set<String> = []
        let path = "a/path/to/an/element"
        let type: Identifiers.FilesAndGroups.ElementType = .localized

        let expectedIdentifier = #"""
FE8B6DB242F1FFE0B40C2A17 /* a/path/to/an/element */
"""#

        // Act

        let identifier = Identifiers.FilesAndGroups.element(
            path,
            type: type,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(identifier, expectedIdentifier)
    }

    func test_filesAndGroups_element_type_coreData() {
        // Arrange

        var hashCache: Set<String> = []
        let path = "a/path/to/an/element"
        let type: Identifiers.FilesAndGroups.ElementType = .coreData

        let expectedIdentifier = #"""
FEDBE1272349F408494E9A09 /* a/path/to/an/element */
"""#

        // Act

        let identifier = Identifiers.FilesAndGroups.element(
            path,
            type: type,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(identifier, expectedIdentifier)
    }

    // MARK: - Targets.subIdentifier

    // MARK: hashCache

    func test_targets_subIdentifier_hashCache_noCollision() {
        // Arrange

        var hashCache: [UInt8: Set<String>] = [:]
        let targetID: TargetID = "//a/target some-config"
        let shard: UInt8 = 42

        let expectedSubIdentifier = Identifiers.Targets.SubIdentifier(
            shard: #"2A"#,
            hash: #"A60E6F34"#
        )
        let expectedModifiedHashCache: [UInt8: Set<String>] = [
            42: ["A60E6F34"],
        ]

        // Act

        let subIdentifier = Identifiers.Targets.subIdentifier(
            targetID,
            shard: shard,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(subIdentifier, expectedSubIdentifier)
        XCTAssertNoDifference(hashCache, expectedModifiedHashCache)
    }

    func test_targets_subIdentifier_hashCache_collision() {
        // Arrange

        var hashCache: [UInt8: Set<String>] = [
            1: ["A60E6F34"],
            42: ["C8905A0B"],
        ]
        let targetID: TargetID = "//a/target some-config"
        let shard: UInt8 = 1

        let expectedSubIdentifier = Identifiers.Targets.SubIdentifier(
            shard: #"01"#,
            hash: #"C8905A0B"#
        )
        let expectedModifiedHashCache: [UInt8: Set<String>] = [
            1: [
                // Original
                "A60E6F34",

                // Added
                "C8905A0B",
            ],
            42: [
                // Original
                "C8905A0B",
            ],
        ]

        // Act

        let subIdentifier = Identifiers.Targets.subIdentifier(
            targetID,
            shard: shard,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(subIdentifier, expectedSubIdentifier)
        XCTAssertNoDifference(hashCache, expectedModifiedHashCache)
    }

    func test_targets_subIdentifier_hashCache_multipleCollisions() {
        // Arrange

        var hashCache: [UInt8: Set<String>] = [
            3: [
                "A60E6F34",
                "C8905A0B",
                "725F054F",
            ],
        ]
        let targetID: TargetID = "//a/target some-config"
        let shard: UInt8 = 3

        let expectedSubIdentifier = Identifiers.Targets.SubIdentifier(
            shard: #"03"#,
            hash: #"FB802152"#
        )
        let expectedModifiedHashCache: [UInt8: Set<String>] = [
            3: [
                // Original
                "A60E6F34", // collision 1
                "C8905A0B", // collision 2
                "725F054F", // collision 3

                // Added
                "FB802152",
            ],
        ]

        // Act

        let subIdentifier = Identifiers.Targets.subIdentifier(
            targetID,
            shard: shard,
            hashCache: &hashCache
        )

        // Assert

        XCTAssertEqual(subIdentifier, expectedSubIdentifier)
        XCTAssertNoDifference(hashCache, expectedModifiedHashCache)
    }

}
