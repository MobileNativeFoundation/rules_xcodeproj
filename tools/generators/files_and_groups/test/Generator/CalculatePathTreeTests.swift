import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CalculatePathTreeTests: XCTestCase {
    
    // MARK: - empty

    func test_empty() {
        // Arrange

        let paths: Set<BazelPath> = []

        let expectedPathTree = PathTreeNode(name: "")

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

        let expectedPathTree = PathTreeNode(
            name: "",
            children: [
                .init(name: "0"),
                .init(
                    name: "a",
                    children: [
                        .init(name: "1"),
                        .init(name: "2"),
                    ]
                ),
                .init(
                    name: "b",
                    children: [
                        .init(name: "0"),
                        .init(name: "3"),
                    ]
                ),
                .init(
                    name: "c",
                    children: [
                        .init(
                            name: "d",
                            children: [
                                .init(name: "2"),
                                .init(name: "6"),
                            ]
                        ),
                        .init(
                            name: "z",
                            children: [
                                .init(name: "1"),
                            ]
                        ),
                    ]
                ),
                .init(name: "d"),
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
        
        let expectedPathTree = PathTreeNode(
            name: "",
            children: [
                .init(
                    name: "file_or_folder",
                    isFolder: true
                ),
                .init(
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

extension PathTreeNode: Equatable {
    public static func == (lhs: PathTreeNode, rhs: PathTreeNode) -> Bool {
        return (lhs.name, lhs.isFolder, lhs.children) ==
            (rhs.name, rhs.isFolder, rhs.children)
    }
}
