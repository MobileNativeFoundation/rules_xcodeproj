import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateFileTests: XCTestCase {

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
                type: .fileReference
            )
        ]

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
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

    func test_element_sortOrder_file() {
        // Arrange

        let node = PathTreeNode(name: "node_name", isFolder: false)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.sortOrder, .fileLike)
    }

    func test_element_sortOrder_folderTypeFile() {
        // Arrange

        let node = PathTreeNode(name: "node_name.xcassets", isFolder: true)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.sortOrder, .fileLike)
    }

    func test_element_sortOrder_folder() {
        // Arrange

        let node = PathTreeNode(name: "node_name", isFolder: true)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.sortOrder, .groupLike)
    }

    // MARK: element.content

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
{isa = PBXFileReference; path = "a path"; sourceTree = SOURCE_ROOT; }
"""#

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    // MARK: element.content - lastKnownFileType

    func test_element_content_lastKnownFileType_file() {
        // Arrange

        let node = PathTreeNode(name: "node_name.bazel")
        let parentBazelPath = BazelPath("a/bazel/path")
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .group, name: nil, path: "a_path"
            ),
            resolvedRepository: nil
        )

        let expectedContent = #"""
{isa = PBXFileReference; lastKnownFileType = text.script.python; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    func test_element_content_lastKnownFileType_folder() {
        // Arrange

        let node = PathTreeNode(name: "node_name", isFolder: true)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .absolute, name: nil, path: "a_path"
            ),
            resolvedRepository: nil
        )

        let expectedContent = #"""
{isa = PBXFileReference; lastKnownFileType = folder; path = a_path; sourceTree = "<absolute>"; }
"""#

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    func test_element_content_lastKnownFileType_folderLikeType() {
        // Arrange

        let node = PathTreeNode(name: "node_name.bundle", isFolder: true)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .group, name: nil, path: "a_path"
            ),
            resolvedRepository: nil
        )

        let expectedContent = #"""
{isa = PBXFileReference; lastKnownFileType = wrapper.cfbundle; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    // MARK: element.content - explicitFileType

    func test_element_content_explicitFileType_BUILD() {
        // Arrange

        let node = PathTreeNode(name: "BUILD")
        let parentBazelPath = BazelPath("a/bazel/path")
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .group, name: nil, path: "a_path"
            ),
            resolvedRepository: nil
        )

        let expectedContent = #"""
{isa = PBXFileReference; explicitFileType = text.script.python; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    func test_element_content_explicitFileType_Podfile() {
        // Arrange

        let node = PathTreeNode(name: "Podfile")
        let parentBazelPath = BazelPath("a/bazel/path")
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .group, name: nil, path: "a_path"
            ),
            resolvedRepository: nil
        )

        let expectedContent = #"""
{isa = PBXFileReference; explicitFileType = text.script.ruby; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
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
{isa = PBXFileReference; name = "a name"; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    // MARK: - bazelPath

    func test_bazelPath() {
        // Arrange

        let node = PathTreeNode(name: "node_name", isFolder: true)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)

        let expectedBazelPath = BazelPath(
            "a/bazel/path/node_name",
            isFolder: true
        )

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertNoDifference(result.bazelPath, expectedBazelPath)
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
                isGroup: false,
                specialRootGroupType: specialRootGroupType
            )
        ]

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: specialRootGroupType,
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
