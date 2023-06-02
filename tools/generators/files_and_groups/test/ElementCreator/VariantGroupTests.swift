import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class VariantGroupTests: XCTestCase {

    // MARK: identifier

    func test_identifier() {
        // Arrange

        let name = "Localizable.strings"
        let bazelPathStr = "a/bazel/path/Localizable.strings"

        let stubbedIdentifier = "1234abcd"
        var createIdentifierPath: String?
        var createIdentifierType: Identifiers.FilesAndGroups.ElementType?
        let createIdentifier: ElementCreator.Environment.CreateIdentifier
            = { path, type in
                createIdentifierPath = path
                createIdentifierType = type
                return stubbedIdentifier
            }

        let expectedElementIdentifierPath = "a/bazel/path/Localizable.strings"

        // Act

        let element = ElementCreator.variantGroup(
            name: name,
            bazelPathStr: bazelPathStr,
            sourceTree: .group,
            childIdentifiers: ["a /* a */"],
            createIdentifier: createIdentifier
        )

        // Assert

        XCTAssertEqual(createIdentifierPath, expectedElementIdentifierPath)
        XCTAssertEqual(createIdentifierType, .localized)
        XCTAssertEqual(element.identifier, stubbedIdentifier)
    }

    // MARK: sortOrder

    func test_sortOrder() {
        // Arrange

        let name = "Localizable.strings"
        let bazelPathStr = "a/bazel/path/Localizable.strings"

        // Act

        let element = ElementCreator.variantGroup(
            name: name,
            bazelPathStr: bazelPathStr,
            sourceTree: .group,
            childIdentifiers: ["a /* a */"],
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(element.sortOrder, .fileLike)
    }

    // MARK: content

    // MARK: content - children

    func test_content_children() {
        // Arrange

        let name = "Localizable.strings"
        let bazelPathStr = "a/bazel/path/Localizable.strings"
        let sourceTree = SourceTree.absolute
        let childIdentifiers = [
            "a /* a/path */",
            "1 /* one */",
        ]

        let expectedContent = #"""
{
			isa = PBXVariantGroup;
			children = (
				a /* a/path */,
				1 /* one */,
			);
			name = Localizable.strings;
			sourceTree = "<absolute>";
		}
"""#

        // Act

        let element = ElementCreator.variantGroup(
            name: name,
            bazelPathStr: bazelPathStr,
            sourceTree: sourceTree,
            childIdentifiers: childIdentifiers,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertNoDifference(element.content, expectedContent)
    }

    // MARK: content - name

    func test_content_name() {
        // Arrange

        let name = "unprocessed content.json"
        let bazelPathStr = "a/bazel/path/unprocessed content.json"

        let expectedContent = #"""
{
			isa = PBXVariantGroup;
			children = (
				a /* a */,
			);
			name = "unprocessed content.json";
			sourceTree = "<group>";
		}
"""#

        // Act

        let element = ElementCreator.variantGroup(
            name: name,
            bazelPathStr: bazelPathStr,
            sourceTree: .group,
            childIdentifiers: ["a /* a */"],
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertNoDifference(element.content, expectedContent)
    }

    // MARK: content - sourceTree

    func test_content_sourceTree() {
        // Arrange

        let name = "Localizable.strings"
        let bazelPathStr = "a/bazel/path/Localizable.strings"
        let sourceTree = SourceTree.sourceRoot

        let expectedContent = #"""
{
			isa = PBXVariantGroup;
			children = (
				a /* a */,
			);
			name = Localizable.strings;
			sourceTree = SOURCE_ROOT;
		}
"""#

        // Act

        let element = ElementCreator.variantGroup(
            name: name,
            bazelPathStr: bazelPathStr,
            sourceTree: sourceTree,
            childIdentifiers: ["a /* a */"],
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertNoDifference(element.content, expectedContent)
    }
}
