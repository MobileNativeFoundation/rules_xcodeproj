import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CalculatePathTreeTests: XCTestCase {

    // MARK: - empty

    func test_empty() {
        // Arrange

        let paths: [BazelPath] = []
        let generatedPaths: [GeneratedPath] = []

        let expectedPathTree: [PathTreeNode] = []

        // Act

        let pathTree = Generator
            .calculatePathTree(paths: paths, generatedPaths: generatedPaths)

        // Assert

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }

    // MARK: - sort

    func test_sort_children() {
        // Arrange

        let paths: [BazelPath] = [
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
        let generatedPaths: [GeneratedPath] = [
            .init(config: "config2", package: "c/d", path: "a/gen/path"),
            .init(config: "config1", package: "c/d", path: "a/gen/path"),
            .init(
                config: "config3",
                package: "",
                path: "gen/folder"
            ),
            .init(config: "config4", package: "c", path: "gen"),
        ]

        let expectedPathTree: [PathTreeNode] = [
            .generatedFiles(.singleConfig(
                path: "config3/bin",
                children: [
                    .group(
                        name: "gen",
                        children: [
                            .file("folder")
                        ]
                    ),
                ]
            )),
            .file("0"),
            .group(
                name: "a",
                children: [
                    .file("1"),
                    .file("2"),
                ]
            ),
            .group(
                name: "b",
                children: [
                    .file("0"),
                    .file("3"),
                ]
            ),
            .group(
                name: "c",
                children: [
                    .generatedFiles(.singleConfig(
                        path: "config4/bin/c",
                        children: [
                            .file("gen"),
                        ]
                    )),
                    .group(
                        name: "d",
                        children: [
                            .generatedFiles(.multipleConfigs([
                                .init(
                                    name: "config1",
                                    path: "config1/bin/c/d",
                                    children: [
                                        .group(
                                            name: "a",
                                            children: [
                                                .group(
                                                    name: "gen",
                                                    children: [
                                                        .file("path"),
                                                    ]
                                                ),
                                            ]
                                        ),
                                    ]
                                ),
                                .init(
                                    name: "config2",
                                    path: "config2/bin/c/d",
                                    children: [
                                        .group(
                                            name: "a",
                                            children: [
                                                .group(
                                                    name: "gen",
                                                    children: [
                                                        .file("path"),
                                                    ]
                                                ),
                                            ]
                                        ),
                                    ]
                                ),
                            ])),
                            .file("2"),
                            .file("6"),
                        ]
                    ),
                    .group(
                        name: "z",
                        children: [
                            .file("1"),
                        ]
                    ),
                ]
            ),
            .file("d"),
        ]

        // Act

        let pathTree = Generator.calculatePathTree(
            paths: paths,
            generatedPaths: generatedPaths
        )

        // Assert

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }
}
