import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CalculatePathTreeTests: XCTestCase {
    
    // MARK: - empty

    func test_empty() {
        // Arrange

        let paths: Set<BazelPath> = []

        let expectedPathTree = PathTreeNode.Group(children: [])

        // Act

        let pathTree = Generator.calculatePathTree(paths: paths)

        // Assert

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }

    // MARK: - sort

    func test_sort_children() {
        // Arrange

        let paths: Set<BazelPath> = [
            "c/z/1",
            "c/d/6",
            "b/3",
            "a/2",
            "0",
            "a/1",
            "b/0",
            "d",
            "c/d/2",
        ]

        let expectedPathTree = PathTreeNode.Group(
            children: [
                .file(name: "0"),
                .group(
                    name: "a",
                    children: [
                        .file(name: "1"),
                        .file(name: "2"),
                    ]
                ),
                .group(
                    name: "b",
                    children: [
                        .file(name: "0"),
                        .file(name: "3"),
                    ]
                ),
                .group(
                    name: "c",
                    children: [
                        .group(
                            name: "d",
                            children: [
                                .file(name: "2"),
                                .file(name: "6"),
                            ]
                        ),
                        .group(
                            name: "z",
                            children: [
                                .file(name: "1"),
                            ]
                        ),
                    ]
                ),
                .file(name: "d"),
            ]
        )

        // Act

        let pathTree = Generator.calculatePathTree(paths: paths)

        // Assert

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }

    func test_sort_folderBeforeFile() {
        // Arrange

        let paths: Set<BazelPath> = [
            .init("file_or_folder", isFolder: false),
            .init("file_or_folder", isFolder: true),
        ]
        
        let expectedPathTree = PathTreeNode.Group(
            children: [
                .file(
                    name: "file_or_folder",
                    isFolder: true
                ),
                .file(
                    name: "file_or_folder",
                    isFolder: false
                ),
            ]
        )

        // Act

        let pathTree = Generator.calculatePathTree(paths: paths)

        // Assert

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }
}
