import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class SynchronizedFoldersTests: XCTestCase {

    // MARK: - CreateFileElement

    func test_createFileElement_synchronizedFolder() {
        // Arrange

        let createAttributes = ElementCreator.CreateAttributes.mock(
            elementAttributes: .init(
                sourceTree: .group,
                name: nil,
                path: "Sources"
            ),
            resolvedRepository: nil
        )
        let createFileElement = ElementCreator.CreateFileElement(
            createAttributes: createAttributes.mock,
            createIdentifier: ElementCreator.Stubs.createIdentifier,
            synchronizedFolders: ["a/Sources"],
            callable: { _, _, _, _, _, _ in
                XCTFail("Synchronized folders don't create a file reference")
                fatalError()
            }
        )

        let expectedElement = Element(
            name: "Sources",
            object: .init(
                identifier: Identifiers.FilesAndGroups
                    .synchronizedRootGroup("a/Sources", name: "Sources"),
                content: """
{isa = PBXFileSystemSynchronizedRootGroup; explicitFileTypes = {}; \
explicitFolders = (); path = Sources; sourceTree = "<group>"; }
"""
            ),
            sortOrder: .groupLike
        )

        // Act

        let result = createFileElement(
            name: "Sources",
            ext: nil,
            bazelPath: "a/Sources",
            bazelPathType: .workspace
        )

        // Assert

        XCTAssertNoDifference(result.element, expectedElement)
    }

    func test_createFileElement_otherPathsUseCallable() {
        // Arrange

        let stubbedElement = Element(
            name: "a.swift",
            object: .init(identifier: "FILE_ID", content: "FILE_CONTENT"),
            sortOrder: .fileLike
        )
        let createFileElement = ElementCreator.CreateFileElement(
            createAttributes: ElementCreator.Stubs.createAttributes,
            createIdentifier: ElementCreator.Stubs.createIdentifier,
            synchronizedFolders: ["a/Sources"],
            callable: { _, _, _, _, _, _ in
                return (element: stubbedElement, resolvedRepository: nil)
            }
        )

        // Act

        let result = createFileElement(
            name: "a.swift",
            ext: "swift",
            bazelPath: "a/Other/a.swift",
            bazelPathType: .workspace
        )

        // Assert

        XCTAssertNoDifference(result.element, stubbedElement)
    }

    // MARK: - removingPathsInSynchronizedFolders

    func test_removingPathsInSynchronizedFolders() {
        // Arrange

        let paths: [BazelPath] = [
            "a/BUILD",
            "a/Sources",
            "a/Sources/A.swift",
            "a/Sources/Nested/B.swift",
            "a/SourcesOther/C.swift",
            "b/Sources/D.swift",
            "",
        ]
        let expectedPaths: [BazelPath] = [
            "a/BUILD",
            "a/Sources",
            "a/SourcesOther/C.swift",
            "b/Sources/D.swift",
            "",
        ]

        // Act

        let result = removingPathsInSynchronizedFolders(
            paths,
            synchronizedFolders: ["a/Sources"]
        )

        // Assert

        XCTAssertNoDifference(result, expectedPaths)
    }

    func test_removingPathsInSynchronizedFolders_noFolders() {
        let paths: [BazelPath] = ["a/Sources/A.swift"]

        XCTAssertNoDifference(
            removingPathsInSynchronizedFolders(paths, synchronizedFolders: []),
            paths
        )
    }
}
