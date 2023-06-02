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
        let (
            createIdentifier,
            createIdentifierTracker
        ) = ElementCreator.CreateIdentifier.mock(identifier: stubbedIdentifier)

        let expectedCreateIdentifierCalled: [
            ElementCreator.CreateIdentifier.MockTracker.Called
        ] = [
            .init(
                path: "a/bazel/path/Localizable.strings",
                type: .localized
            )
        ]

        // Act

        let element = ElementCreator.variantGroup(
            name: name,
            bazelPathStr: bazelPathStr,
            sourceTree: .group,
            childIdentifiers: ["a /* a */"],
            createIdentifier: createIdentifier
        )

        // Assert

        XCTAssertNoDifference(
            createIdentifierTracker.called,
            expectedCreateIdentifierCalled
        )
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
            createIdentifier: ElementCreator.Stubs.createIdentifier
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
            createIdentifier: ElementCreator.Stubs.createIdentifier
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
            createIdentifier: ElementCreator.Stubs.createIdentifier
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
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(element.content, expectedContent)
    }
}
