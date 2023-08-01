import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateVariantGroupElementTests: XCTestCase {

    // MARK: identifier

    func test_identifier() {
        // Arrange

        let name = "Localizable.strings"
        let path = "a/bazel/path/Localizable.strings"

        let expectedCreateIdentifierCalled: [
            ElementCreator.CreateIdentifier.MockTracker.Called
        ] = [
            .init(
                path: "a/bazel/path/Localizable.strings",
                type: .localized
            )
        ]
        let stubbedIdentifier = "1234abcd"
        let createIdentifier = ElementCreator.CreateIdentifier
            .mock(identifier: stubbedIdentifier)

        // Act

        let element = ElementCreator.CreateVariantGroupElement.defaultCallable(
            name: name,
            path: path,
            childIdentifiers: ["a /* a */"],
            createIdentifier: createIdentifier.mock
        )

        // Assert

        XCTAssertNoDifference(
            createIdentifier.tracker.called,
            expectedCreateIdentifierCalled
        )
        XCTAssertEqual(element.object.identifier, stubbedIdentifier)
    }

    // MARK: sortOrder

    func test_sortOrder() {
        // Arrange

        let name = "Localizable.strings"
        let path = "a/bazel/path/Localizable.strings"

        // Act

        let element = ElementCreator.CreateVariantGroupElement.defaultCallable(
            name: name,
            path: path,
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
        let path = "a/bazel/path/Localizable.strings"
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
			sourceTree = "<group>";
		}
"""#

        // Act

        let element = ElementCreator.CreateVariantGroupElement.defaultCallable(
            name: name,
            path: path,
            childIdentifiers: childIdentifiers,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(element.object.content, expectedContent)
    }

    // MARK: content - name

    func test_content_name() {
        // Arrange

        let name = "unprocessed content.json"
        let path = "a/bazel/path/unprocessed content.json"

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

        let element = ElementCreator.CreateVariantGroupElement.defaultCallable(
            name: name,
            path: path,
            childIdentifiers: ["a /* a */"],
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(element.object.content, expectedContent)
    }

    // MARK: content - sourceTree

    func test_content_sourceTree() {
        // Arrange

        let name = "Localizable.strings"
        let path = "a/bazel/path/Localizable.strings"

        let expectedContent = #"""
{
			isa = PBXVariantGroup;
			children = (
				a /* a */,
			);
			name = Localizable.strings;
			sourceTree = "<group>";
		}
"""#

        // Act

        let element = ElementCreator.CreateVariantGroupElement.defaultCallable(
            name: name,
            path: path,
            childIdentifiers: ["a /* a */"],
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(element.object.content, expectedContent)
    }
}
