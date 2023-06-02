import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateGroupTests: XCTestCase {

    // MARK: - element

    // MARK: element.identifier

    func test_element_identifier() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")

        let stubbedIdentifier = "1234abcd"
        let (
            createIdentifier,
            createIdentifierTracker
        ) = ElementCreator.CreateIdentifier.mock(identifier: stubbedIdentifier)

        let expectedCreateIdentifierCalled: [
            ElementCreator.CreateIdentifier.MockTracker.Called
        ] = [
            .init(
                path: "a/bazel/path/node_name",
                type: .group
            )
        ]

        // Act

        let result = ElementCreator.CreateGroup.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: createIdentifier
        )

        // Assert

        XCTAssertNoDifference(
            createIdentifierTracker.called,
            expectedCreateIdentifierCalled
        )
        XCTAssertEqual(result.element.identifier, stubbedIdentifier)
    }

    // MARK: element.sortOrder

    func test_element_sortOrder() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")

        // Act

        let result = ElementCreator.CreateGroup.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
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
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .absolute, name: nil, path: "a_path"
            ),
            resolvedRepository: nil
        )

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

        let result = ElementCreator.CreateGroup.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: childIdentifiers,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(result.element.content, expectedContent)
    }

    // MARK: element.content - elementAttributes

    func test_element_content_createAttributes() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .sourceRoot, name: nil, path: "a path"
            ),
            resolvedRepository: nil
        )

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

        let result = ElementCreator.CreateGroup.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(result.element.content, expectedContent)
    }

    // MARK: element.content - name

    func test_element_content_name() {
        // Arrange

        let node = PathTreeNode(name: "node_name")
        let parentBazelPath = BazelPath("a/bazel/path")
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .group, name: "a name", path: "a_path"
            ),
            resolvedRepository: nil
        )

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

        let result = ElementCreator.CreateGroup.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
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

        let stubbedResolvedRepository = ResolvedRepository(
            sourcePath: "a/source/path", mappedPath: "/a/mapped/path"
        )
        let (
            createAttributes,
            createAttributesTracker
        ) = ElementCreator.CreateAttributes.mock(
            elementAttributes: .init(
                sourceTree: .absolute, name: "a_name", path: "a_path"
            ),
            resolvedRepository: stubbedResolvedRepository
        )

        let expectedCreateAttributesCalled: [
            ElementCreator.CreateAttributes.MockTracker.Called
        ] = [
            .init(
                name: node.name,
                bazelPath: BazelPath("a/bazel/path/node_name", isFolder: false),
                isGroup: true,
                specialRootGroupType: specialRootGroupType
            )
        ]

        // Act

        let result = ElementCreator.CreateGroup.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: [],
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(
            createAttributesTracker.called,
            expectedCreateAttributesCalled
        )
        XCTAssertEqual(result.resolvedRepository, stubbedResolvedRepository)
    }
}
