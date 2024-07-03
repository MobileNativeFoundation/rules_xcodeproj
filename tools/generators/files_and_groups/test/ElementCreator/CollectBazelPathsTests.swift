import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CollectBazelPathsTests: XCTestCase {
    func test_file_includeSelf() {
        // Arrange

        let node = PathTreeNode.file(
            name: "path",
            isFolder: false
        )
        let bazelPath = BazelPath(
            "a/bazel/path",
            isFolder: false
        )
        let includeSelf = true

        let expectedBazelPaths: [BazelPath] = [
            BazelPath("a/bazel/path", isFolder: false),
        ]

        // Act

        let bazelPaths = ElementCreator.CollectBazelPaths.defaultCallable(
            node: node,
            bazelPath: bazelPath,
            includeSelf: includeSelf
        )

        // Assert

        XCTAssertNoDifference(bazelPaths, expectedBazelPaths)
    }

    func test_file_notIncludeSelf() {
        // Arrange

        let node = PathTreeNode.file(
            name: "path",
            isFolder: true
        )
        let bazelPath = BazelPath(
            "a/bazel/path",
            isFolder: true
        )
        let includeSelf = false

        let expectedBazelPaths: [BazelPath] = []

        // Act

        let bazelPaths = ElementCreator.CollectBazelPaths.defaultCallable(
            node: node,
            bazelPath: bazelPath,
            includeSelf: includeSelf
        )

        // Assert

        XCTAssertNoDifference(bazelPaths, expectedBazelPaths)
    }

    func test_group_includeSelf() {
        // Arrange

        let node = PathTreeNode.group(
            name: "path",
            children: [
                .file(name: "file", isFolder: false),
                .group(name: "directory", children: [
                    .file(name: "file_or_folder", isFolder: true),
                    .file(name: "file_or_folder", isFolder: false),
                ]),
                .file(name: "folder", isFolder: true),
            ]
        )
        let bazelPath = BazelPath(
            "a/bazel/path",
            isFolder: false
        )
        let includeSelf = true

        let expectedBazelPaths = [
            BazelPath("a/bazel/path/file", isFolder: false),
            BazelPath("a/bazel/path/directory/file_or_folder", isFolder: true),
            BazelPath("a/bazel/path/directory/file_or_folder", isFolder: false),
            BazelPath("a/bazel/path/directory", isFolder: false),
            BazelPath("a/bazel/path/folder", isFolder: true),
            BazelPath("a/bazel/path", isFolder: false),
        ]

        // Act

        let bazelPaths = ElementCreator.CollectBazelPaths.defaultCallable(
            node: node,
            bazelPath: bazelPath,
            includeSelf: includeSelf
        )

        // Assert

        XCTAssertNoDifference(bazelPaths, expectedBazelPaths)
    }

    func test_group_notIncludeSelf() {
        // Arrange

        let node = PathTreeNode.group(
            name: "path",
            children: [
                .file(name: "file", isFolder: false),
                .group(name: "directory", children: [
                    .file(name: "file_or_folder", isFolder: true),
                    .file(name: "file_or_folder", isFolder: false),
                ]),
                .file(name: "folder", isFolder: true),
            ]
        )
        let bazelPath = BazelPath(
            "a/bazel/path",
            isFolder: false
        )
        let includeSelf = false

        let expectedBazelPaths = [
            BazelPath("a/bazel/path/file", isFolder: false),
            BazelPath("a/bazel/path/directory/file_or_folder", isFolder: true),
            BazelPath("a/bazel/path/directory/file_or_folder", isFolder: false),
            BazelPath("a/bazel/path/directory", isFolder: false),
            BazelPath("a/bazel/path/folder", isFolder: true),
        ]

        // Act

        let bazelPaths = ElementCreator.CollectBazelPaths.defaultCallable(
            node: node,
            bazelPath: bazelPath,
            includeSelf: includeSelf
        )

        // Assert

        XCTAssertNoDifference(bazelPaths, expectedBazelPaths)
    }
}
