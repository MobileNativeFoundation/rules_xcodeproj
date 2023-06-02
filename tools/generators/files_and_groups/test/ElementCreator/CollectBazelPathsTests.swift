import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CollectBazelPathsTests: XCTestCase {
    func test() {
        // Arrange

        let node = PathTreeNode(
            name: "path",
            isFolder: false,
            children: [
                .init(name: "file", isFolder: false),
                .init(name: "directory", children: [
                    .init(name: "file_or_folder", isFolder: true),
                    .init(name: "file_or_folder", isFolder: false),
                ]),
                .init(name: "folder", isFolder: true),
            ]
        )
        let bazelPath = BazelPath(
            "a/bazel/path",
            isFolder: false
        )

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
            bazelPath: bazelPath
        )

        // Assert

        XCTAssertNoDifference(bazelPaths, expectedBazelPaths)
    }
}
