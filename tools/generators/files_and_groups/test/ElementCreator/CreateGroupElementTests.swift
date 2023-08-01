import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateGroupElementTests: XCTestCase {

    // MARK: - element

    // MARK: element.identifier

    func test_element_identifier() {
        // Arrange

        let name = "node_name"
        let bazelPath = BazelPath("a/bazel/path/node_name")

        let expectedCreateIdentifierCalled: [
            ElementCreator.CreateIdentifier.MockTracker.Called
        ] = [
            .init(
                path: bazelPath.path,
                type: .group
            )
        ]
        let stubbedIdentifier = "1234abcd"
        let createIdentifier = ElementCreator.CreateIdentifier
            .mock(identifier: stubbedIdentifier)

        // Act

        let result = ElementCreator.CreateGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: createIdentifier.mock
        )

        // Assert

        XCTAssertNoDifference(
            createIdentifier.tracker.called,
            expectedCreateIdentifierCalled
        )
        XCTAssertEqual(result.element.object.identifier, stubbedIdentifier)
    }

    // MARK: element.sortOrder

    func test_element_sortOrder() {
        // Arrange

        let name = "node_name"
        let bazelPath = BazelPath("a/bazel/path/node_name")

        // Act

        let result = ElementCreator.CreateGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
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

        let name = "node_name"
        let bazelPath = BazelPath("a/bazel/path/node_name")
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

        let result = ElementCreator.CreateGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            childIdentifiers: childIdentifiers,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(result.element.object.content, expectedContent)
    }

    // MARK: element.content - elementAttributes

    func test_element_content_createAttributes() {
        // Arrange

        let name = "node_name"
        let bazelPath = BazelPath("a/bazel/path/node_name")
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

        let result = ElementCreator.CreateGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(result.element.object.content, expectedContent)
    }

    // MARK: element.content - name

    func test_element_content_name() {
        // Arrange

        let name = "node_name"
        let bazelPath = BazelPath("a/bazel/path/node_name")
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

        let result = ElementCreator.CreateGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            childIdentifiers: [],
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(result.element.object.content, expectedContent)
    }

    // MARK: - resolvedRepository

    func test_resolvedRepository() {
        // Arrange

        let name = "node_name"
        let bazelPath = BazelPath("a/bazel/path/node_name")
        let specialRootGroupType = SpecialRootGroupType.bazelGenerated

        let expectedCreateAttributesCalled: [
            ElementCreator.CreateAttributes.MockTracker.Called
        ] = [
            .init(
                name: name,
                bazelPath: bazelPath,
                isGroup: true,
                specialRootGroupType: specialRootGroupType
            )
        ]
        let stubbedResolvedRepository = ResolvedRepository(
            sourcePath: "a/source/path", mappedPath: "/a/mapped/path"
        )
        let createAttributes = ElementCreator.CreateAttributes.mock(
            elementAttributes: .init(
                sourceTree: .absolute, name: "a_name", path: "a_path"
            ),
            resolvedRepository: stubbedResolvedRepository
        )

        // Act

        let result = ElementCreator.CreateGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: [],
            createAttributes: createAttributes.mock,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(
            createAttributes.tracker.called,
            expectedCreateAttributesCalled
        )
        XCTAssertEqual(result.resolvedRepository, stubbedResolvedRepository)
    }
}
