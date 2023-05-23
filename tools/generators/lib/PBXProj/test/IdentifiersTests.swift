import CustomDump
import PBXProj
import XCTest

final class IdentifiersTests: XCTestCase {

    // MARK: - FilesAndGroups.element

    // MARK: hashCache

    func test_filesAndGroups_element_hashCache_noCollision() {
        // Arrange

        var hashCache: Set<String> = []
        let path = "a/path/to/a/file"
        let type: Identifiers.FilesAndGroups.ElementType = .fileReference

        let expectedIdentifier = #"""
FF9127BCB9F1C1C990ADB87F /* a/path/to/a/file */
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
FFC218EE063FFEACFDC4CCBF /* a/path/to/a/file */
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
FFD9F54B134D73636F095974 /* a/path/to/a/file */
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
FFF8A9154DBAF0B6DF9804E2 /* a/path/to/an/element */
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
FF76BD00D1EAF8EE030DB890 /* a/path/to/an/element */
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
FF8B6DB242F1FFE0B40C2A17 /* a/path/to/an/element */
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
FFDBE1272349F408494E9A09 /* a/path/to/an/element */
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
}
