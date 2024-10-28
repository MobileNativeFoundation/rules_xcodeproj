import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CollectBazelPathsTests: XCTestCase {
    func test_file_includeSelf() {
        // Arrange

        let node = PathTreeNode.file("path")
        let bazelPath = BazelPath("a/bazel/path")
        let includeSelf = true

        let expectedBazelPaths: [BazelPath] = [
            BazelPath("a/bazel/path"),
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

        let node = PathTreeNode.file("path")
        let bazelPath = BazelPath("a/bazel/path")
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
                .file("file"),
                .group(name: "directory", children: [
                    .file("file_or_folder"),
                ]),
                .file("folder"),
            ]
        )
        let bazelPath = BazelPath("a/bazel/path")
        let includeSelf = true

        let expectedBazelPaths = [
            BazelPath("a/bazel/path/file"),
            BazelPath("a/bazel/path/directory/file_or_folder"),
            BazelPath("a/bazel/path/directory"),
            BazelPath("a/bazel/path/folder"),
            BazelPath("a/bazel/path"),
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
                .file("file"),
                .group(name: "directory", children: [
                    .file("file_or_folder"),
                ]),
                .file("folder"),
            ]
        )
        let bazelPath = BazelPath("a/bazel/path")
        let includeSelf = false

        let expectedBazelPaths = [
            BazelPath("a/bazel/path/file"),
            BazelPath("a/bazel/path/directory/file_or_folder"),
            BazelPath("a/bazel/path/directory"),
            BazelPath("a/bazel/path/folder"),
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
