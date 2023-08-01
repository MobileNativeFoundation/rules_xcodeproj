import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateFileElementTests: XCTestCase {

    // MARK: - element

    // MARK: element.identifier

    func test_element_identifier() {
        // Arrange

        let name = "node_name"
        let ext: String? = nil
        let bazelPath = BazelPath("a/bazel/path/node_name")

        let expectedCreateIdentifierCalled: [
            ElementCreator.CreateIdentifier.MockTracker.Called
        ] = [
            .init(
                path: "a/bazel/path/node_name",
                type: .fileReference
            )
        ]
        let stubbedIdentifier = "1234abcd"
        let createIdentifier = ElementCreator.CreateIdentifier
            .mock(identifier: stubbedIdentifier)

        // Act

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
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

    func test_element_sortOrder_file() {
        // Arrange

        let name = "node_name"
        let ext: String? = nil
        let bazelPath = BazelPath("a/bazel/path/node_name", isFolder: false)

        // Act

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.sortOrder, .fileLike)
    }

    func test_element_sortOrder_folderTypeFile() {
        // Arrange

        let name = "node_name"
        let ext = "xcassets"
        let bazelPath = BazelPath(
            "a/bazel/path/node_name.xcassets",
            isFolder: true
        )

        // Act

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.sortOrder, .fileLike)
    }

    func test_element_sortOrder_folder() {
        // Arrange

        let name = "node_name"
        let ext: String? = nil
        let bazelPath = BazelPath(
            "a/bazel/path/node_name",
            isFolder: true
        )

        // Act

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
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

        let name = "node_name"
        let ext: String? = nil
        let bazelPath = BazelPath("a/bazel/path/node_name")
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .sourceRoot, name: nil, path: "a path"
            ),
            resolvedRepository: nil
        )

        let expectedContent = #"""
{isa = PBXFileReference; lastKnownFileType = file; path = "a path"; sourceTree = SOURCE_ROOT; }
"""#

        // Act

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.object.content, expectedContent)
    }

    // MARK: element.content - lastKnownFileType

    func test_element_content_lastKnownFileType_file() {
        // Arrange

        let name = "node_name.bazel"
        let ext = "bazel"
        let bazelPath = BazelPath("a/bazel/path/node_name.bazel")
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

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.object.content, expectedContent)
    }

    func test_element_content_lastKnownFileType_folder() {
        // Arrange

        let name = "node_name"
        let ext: String? = nil
        let bazelPath = BazelPath("a/bazel/path/node_name", isFolder: true)
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

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.object.content, expectedContent)
    }

    func test_element_content_lastKnownFileType_folderLikeType() {
        // Arrange

        let name = "node_name.bundle"
        let ext = "bundle"
        let bazelPath = BazelPath("a/bazel/path/node_name.bundle")
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

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.object.content, expectedContent)
    }

    // MARK: element.content - explicitFileType

    func test_element_content_explicitFileType_BUILD() {
        // Arrange

        let name = "BUILD"
        let ext: String? = nil
        let bazelPath = BazelPath("a/bazel/path/BUILD")
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

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.object.content, expectedContent)
    }

    func test_element_content_explicitFileType_Podfile() {
        // Arrange

        let name = "Podfile"
        let ext: String? = nil
        let bazelPath = BazelPath("a/bazel/path/Podfile")
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

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.object.content, expectedContent)
    }

    // MARK: element.content - name

    func test_element_content_name() {
        // Arrange

        let name = "node_name"
        let ext: String? = nil
        let bazelPath = BazelPath("a/bazel/path/node_name")
        let createAttributes = ElementCreator.CreateAttributes.stub(
            elementAttributes: ElementAttributes(
                sourceTree: .group, name: "a name", path: "a_path"
            ),
            resolvedRepository: nil
        )

        let expectedContent = #"""
{isa = PBXFileReference; lastKnownFileType = file; name = "a name"; path = a_path; sourceTree = "<group>"; }
"""#

        // Act

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: nil,
            createAttributes: createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier
        )

        // Assert

        XCTAssertEqual(result.element.object.content, expectedContent)
    }


    // MARK: - resolvedRepository

    func test_resolvedRepository() {
        // Arrange

        let name = "node_name"
        let ext: String? = nil
        let bazelPath = BazelPath("a/bazel/path/node_name")
        let specialRootGroupType = SpecialRootGroupType.bazelGenerated

        let expectedCreateAttributesCalled: [
            ElementCreator.CreateAttributes.MockTracker.Called
        ] = [
            .init(
                name: name,
                bazelPath: bazelPath,
                isGroup: false,
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

        let result = ElementCreator.CreateFileElement.defaultCallable(
            name: name,
            ext: ext,
            bazelPath: bazelPath,
            specialRootGroupType: specialRootGroupType,
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
