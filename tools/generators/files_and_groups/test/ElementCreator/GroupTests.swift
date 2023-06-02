import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class GroupTests: XCTestCase {

    // MARK: - element

    // MARK: element.identifier

    func test_element_identifier() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")

        let stubbedIdentifier = "1234abcd"
        var createIdentifierPath: String?
        var createIdentifierType: Identifiers.FilesAndGroups.ElementType?
        let createIdentifier: ElementCreator.Environment.CreateIdentifier
            = { path, type in
                createIdentifierPath = path
                createIdentifierType = type
                return stubbedIdentifier
            }

        let expectedElementIdentifierPath = "a/bazel/path/node_name"

        // Act

        let result = ElementCreator.group(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: ElementCreator.Stubs.attributes,
            createIdentifier: createIdentifier
        )

        // Assert

        XCTAssertEqual(createIdentifierPath, expectedElementIdentifierPath)
        XCTAssertEqual(createIdentifierType, .group)
        XCTAssertEqual(result.element.identifier, stubbedIdentifier)
    }

    // MARK: element.sortOrder

    func test_element_sortOrder() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")

        // Act

        let result = ElementCreator.group(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: ElementCreator.Stubs.attributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(result.element.sortOrder, .groupLike)
    }

    // MARK: element.content

    // MARK: element.content - children

    func test_element_content_children() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")
        let childIdentifiers = [
            "a /* a/path */",
            "1 /* one */",
        ]

        let createAttributes: ElementCreator.Environment.CreateAttributes
            = { name, bazelPath, isGroup, specialRootGroupType in
                return (
                    ElementAttributes(
                        sourceTree: .absolute, name: nil, path: "a_path"
                    ),
                    nil
                )
            }

        let expectedContent = #"""
{
			isa = PBXGroup;
			children = (
				a /* a/path */,
				1 /* one */,
			);
			path = a_path;
			sourceTree = "<absolute>";
		}
"""#

        // Act

        let result = ElementCreator.group(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: childIdentifiers,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertNoDifference(result.element.content, expectedContent)
    }

    // MARK: element.content - elementAttributes

    func test_element_content_createAttributes() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")

        let createAttributes: ElementCreator.Environment.CreateAttributes
            = { name, bazelPath, isGroup, specialRootGroupType in
                return (
                    ElementAttributes(
                        sourceTree: .sourceRoot, name: nil, path: "a path"
                    ),
                    nil
                )
            }

        let expectedContent = #"""
{
			isa = PBXGroup;
			children = (
			);
			path = "a path";
			sourceTree = SOURCE_ROOT;
		}
"""#

        // Act

        let result = ElementCreator.group(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertNoDifference(result.element.content, expectedContent)
    }

    // MARK: element.content - name

    func test_element_content_name() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")

        let createAttributes: ElementCreator.Environment.CreateAttributes
            = { name, bazelPath, isGroup, specialRootGroupType in
                return (
                    ElementAttributes(
                        sourceTree: .group, name: "a name", path: "a_path"
                    ),
                    nil
                )
            }

        let expectedContent = #"""
{
			isa = PBXGroup;
			children = (
			);
			name = "a name";
			path = a_path;
			sourceTree = "<group>";
		}
"""#

        // Act

        let result = ElementCreator.group(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertNoDifference(result.element.content, expectedContent)
    }

    // MARK: - resolvedRepository

    func test_resolvedRepository() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")
        let specialRootGroupType = SpecialRootGroupType.bazelGenerated

        let stubbedElementAttributes = ElementAttributes(
            sourceTree: .absolute, name: "a_name", path: "a_path"
        )
        let stubbedResolvedRepository = ResolvedRepository(
            sourcePath: "a/source/path", mappedPath: "/a/mapped/path"
        )
        var elementAttributesName: String?
        var elementAttributesBazelPath: BazelPath?
        var elementAttributesIsGroup: Bool?
        var elementAttributesSpecialRootGroupType: SpecialRootGroupType??
        let createAttributes: ElementCreator.Environment.CreateAttributes
            = { name, bazelPath, isGroup, specialRootGroupType in
                elementAttributesName = name
                elementAttributesBazelPath = bazelPath
                elementAttributesIsGroup = isGroup
                elementAttributesSpecialRootGroupType =
                    .some(specialRootGroupType)
                return (stubbedElementAttributes, stubbedResolvedRepository)
            }

        let expectedElementAttributesBazelPath = BazelPath(
            "a/bazel/path/node_name",
            isFolder: false
        )

        // Act

        let result = ElementCreator.group(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: [],
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(elementAttributesName, node.name)
        XCTAssertEqual(
            elementAttributesBazelPath,
            expectedElementAttributesBazelPath
        )
        XCTAssertEqual(elementAttributesIsGroup, true)
        XCTAssertEqual(
            elementAttributesSpecialRootGroupType,
            specialRootGroupType
        )
        XCTAssertEqual(result.resolvedRepository, stubbedResolvedRepository)
    }
}
