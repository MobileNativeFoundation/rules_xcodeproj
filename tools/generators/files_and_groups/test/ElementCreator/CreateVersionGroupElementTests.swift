import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateVersionGroupElementTests: XCTestCase {

    // MARK: - element

    // MARK: element.identifier

    func test_element_identifier() {
        // Arrange

        let name = "node_name"
        let bazelPath = BazelPath("a/bazel/path/node_name")
        let identifier = "1234abcd"

        // Act

        let result = ElementCreator.CreateVersionGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            identifier: identifier,
            childIdentifiers: ["a /* a */"],
            selectedChildIdentifier: nil,
            createAttributes: ElementCreator.Stubs.createAttributes
        )

        // Assert

        XCTAssertEqual(result.element.object.identifier, identifier)
    }

    // MARK: element.sortOrder

    func test_element_sortOrder() {
        // Arrange

        let name = "node_name"
        let bazelPath = BazelPath("a/bazel/path/node_name")

        // Act

        let result = ElementCreator.CreateVersionGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            identifier: "i",
            childIdentifiers: ["a /* a */"],
            selectedChildIdentifier: "a /* a */",
            createAttributes: ElementCreator.Stubs.createAttributes
        )

        // Assert

        XCTAssertEqual(result.element.sortOrder, .fileLike)
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
			isa = XCVersionGroup;
			children = (
				a /* a/path */,
				1 /* one */,
			);
			path = a_path;
			sourceTree = "<absolute>";
			versionGroupType = wrapper.xcdatamodel;
		}
"""#

        // Act

        let result = ElementCreator.CreateVersionGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            identifier: "i",
            childIdentifiers: childIdentifiers,
            selectedChildIdentifier: nil,
            createAttributes: createAttributes
        )

        // Assert

        XCTAssertNoDifference(result.element.object.content, expectedContent)
    }

    // MARK: element.content - currentVersion

    func test_element_content_currentVersion() {
        // Arrange

        let name = "node_name"
        let bazelPath = BazelPath("a/bazel/path/node_name")
        let selectedChildIdentifier = "1 /* one */"
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .absolute, name: nil, path: "a_path"
            ),
            resolvedRepository: nil
        )

        let expectedContent = #"""
{
			isa = XCVersionGroup;
			children = (
				a /* a */,
			);
			currentVersion = 1 /* one */;
			path = a_path;
			sourceTree = "<absolute>";
			versionGroupType = wrapper.xcdatamodel;
		}
"""#

        // Act

        let result = ElementCreator.CreateVersionGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            identifier: "i",
            childIdentifiers: ["a /* a */"],
            selectedChildIdentifier: selectedChildIdentifier,
            createAttributes: createAttributes
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
			isa = XCVersionGroup;
			children = (
				a /* a */,
			);
			path = "a path";
			sourceTree = SOURCE_ROOT;
			versionGroupType = wrapper.xcdatamodel;
		}
"""#

        // Act

        let result = ElementCreator.CreateVersionGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            identifier: "i",
            childIdentifiers: ["a /* a */"],
            selectedChildIdentifier: nil,
            createAttributes: createAttributes
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
			isa = XCVersionGroup;
			children = (
				a /* a */,
			);
			name = "a name";
			path = a_path;
			sourceTree = "<group>";
			versionGroupType = wrapper.xcdatamodel;
		}
"""#

        // Act

        let result = ElementCreator.CreateVersionGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            identifier: "i",
            childIdentifiers: ["a /* a */"],
            selectedChildIdentifier: nil,
            createAttributes: createAttributes
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
                bazelPath: BazelPath("a/bazel/path/node_name", isFolder: false),
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

        let result = ElementCreator.CreateVersionGroupElement.defaultCallable(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: specialRootGroupType,
            identifier: "i",
            childIdentifiers: ["a /* a */"],
            selectedChildIdentifier: nil,
            createAttributes: createAttributes.mock
        )

        // Assert

        XCTAssertNoDifference(
            createAttributes.tracker.called,
            expectedCreateAttributesCalled
        )
        XCTAssertEqual(result.resolvedRepository, stubbedResolvedRepository)
    }
}
