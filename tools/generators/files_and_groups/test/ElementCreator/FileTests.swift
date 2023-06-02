import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class FileTests: XCTestCase {

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

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.attributes,
            createIdentifier: createIdentifier
        )

        // Assert

        XCTAssertEqual(createIdentifierPath, expectedElementIdentifierPath)
        XCTAssertEqual(createIdentifierType, .fileReference)
        XCTAssertEqual(result.element.identifier, stubbedIdentifier)
    }

    // MARK: element.sortOrder

    func test_element_sortOrder_file() {
        // Arrange

        let node = PathTreeNode(name: "node_name", isFolder: false)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.attributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(result.element.sortOrder, .fileLike)
    }

    func test_element_sortOrder_folderTypeFile() {
        // Arrange

        let node = PathTreeNode(name: "node_name.xcassets", isFolder: true)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.attributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(result.element.sortOrder, .fileLike)
    }

    func test_element_sortOrder_folder() {
        // Arrange

        let node = PathTreeNode(name: "node_name", isFolder: true)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.attributes,
            createIdentifier: ElementCreator.Stubs.identifier
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

        let createAttributes: ElementCreator.Environment.CreateAttributes =
            { name, bazelPath, isGroup, specialRootGroupType in
                return (
                    ElementAttributes(
                        sourceTree: .sourceRoot, name: nil, path: "a path"
                    ),
                    nil
                )
            }

        let expectedContent = #"""
{isa = PBXFileReference; path = "a path"; sourceTree = SOURCE_ROOT; }
"""#

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    // MARK: element.content - lastKnownFileType

    func test_element_content_lastKnownFileType_file() {
        // Arrange

        let node = PathTreeNode(name: "node_name.bazel")
        let parentBazelPath = BazelPath("a/bazel/path")

        let createAttributes: ElementCreator.Environment.CreateAttributes =
            { name, bazelPath, isGroup, specialRootGroupType in
                return (
                    ElementAttributes(
                        sourceTree: .group, name: nil, path: "a_path"
                    ),
                    nil
                )
            }

        let expectedContent = #"""
{isa = PBXFileReference; lastKnownFileType = text.script.python; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    func test_element_content_lastKnownFileType_folder() {
        // Arrange

        let node = PathTreeNode(name: "node_name", isFolder: true)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)

        let createAttributes: ElementCreator.Environment.CreateAttributes =
            { name, bazelPath, isGroup, specialRootGroupType in
                return (
                    ElementAttributes(
                        sourceTree: .absolute, name: nil, path: "a_path"
                    ),
                    nil
                )
            }

        let expectedContent = #"""
{isa = PBXFileReference; lastKnownFileType = folder; path = a_path; sourceTree = "<absolute>"; }
"""#

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    func test_element_content_lastKnownFileType_folderLikeType() {
        // Arrange

        let node = PathTreeNode(name: "node_name.bundle", isFolder: true)
        let parentBazelPath = BazelPath("a/bazel/path", isFolder: false)

        let createAttributes: ElementCreator.Environment.CreateAttributes =
            { name, bazelPath, isGroup, specialRootGroupType in
                return (
                    ElementAttributes(
                        sourceTree: .group, name: nil, path: "a_path"
                    ),
                    nil
                )
            }

        let expectedContent = #"""
{isa = PBXFileReference; lastKnownFileType = wrapper.cfbundle; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    // MARK: element.content - explicitFileType

    func test_element_content_explicitFileType_BUILD() {
        // Arrange

        let node = PathTreeNode(name: "BUILD")
        let parentBazelPath = BazelPath("a/bazel/path")

        let createAttributes: ElementCreator.Environment.CreateAttributes =
            { name, bazelPath, isGroup, specialRootGroupType in
                return (
                    ElementAttributes(
                        sourceTree: .group, name: nil, path: "a_path"
                    ),
                    nil
                )
            }

        let expectedContent = #"""
{isa = PBXFileReference; explicitFileType = text.script.python; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
    }

    func test_element_content_explicitFileType_Podfile() {
        // Arrange

        let node = PathTreeNode(name: "Podfile")
        let parentBazelPath = BazelPath("a/bazel/path")

        let createAttributes: ElementCreator.Environment.CreateAttributes =
            { name, bazelPath, isGroup, specialRootGroupType in
                return (
                    ElementAttributes(
                        sourceTree: .group, name: nil, path: "a_path"
                    ),
                    nil
                )
            }

        let expectedContent = #"""
{isa = PBXFileReference; explicitFileType = text.script.ruby; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(result.element.content, expectedContent)
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
{isa = PBXFileReference; name = "a name"; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
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

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.attributes,
            createIdentifier: ElementCreator.Stubs.identifier
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
        let createAttributes: ElementCreator.Environment.CreateAttributes =
            { name, bazelPath, isGroup, specialRootGroupType in
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

        let result = ElementCreator.file(
            node: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: specialRootGroupType,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.identifier
        )

        // Assert

        XCTAssertEqual(elementAttributesName, node.name)
        XCTAssertEqual(
            elementAttributesBazelPath,
            expectedElementAttributesBazelPath
        )
        XCTAssertEqual(elementAttributesIsGroup, false)
        XCTAssertEqual(
            elementAttributesSpecialRootGroupType,
            specialRootGroupType
        )
        XCTAssertEqual(result.resolvedRepository, stubbedResolvedRepository)
    }
}
