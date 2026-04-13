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
        let synchronizedFolders: [SynchronizedFolderTarget] = []

        let expectedPathTree: [PathTreeNode] = []

        // Act

        let pathTree = Generator
            .calculatePathTree(
                paths: paths,
                generatedPaths: generatedPaths,
                synchronizedFolders: synchronizedFolders
            )

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
        let synchronizedFolders: [SynchronizedFolderTarget] = []

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
            generatedPaths: generatedPaths,
            synchronizedFolders: synchronizedFolders
        )

        // Assert

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }

    func test_synchronizedFolder_filtersDescendants() {
        let paths: [BazelPath] = [
            "App/Sources/Feature.swift",
            "App/Resources/icon.png",
            "App/README.md",
        ]
        let generatedPaths: [GeneratedPath] = []
        let synchronizedFolders: [SynchronizedFolderTarget] = [
            .init(
                folderPath: "App/Sources",
                targetIdentifier: "TARGET /* App */",
                targetName: "App",
                includedPaths: ["App/Sources/Feature.swift"],
                excludedPaths: []
            )
        ]

        let expectedPathTree: [PathTreeNode] = [
            .group(
                name: "App",
                children: [
                    .file("README.md"),
                    .group(
                        name: "Resources",
                        children: [
                            .file("icon.png"),
                        ]
                    ),
                    .synchronizedGroup(
                        name: "Sources",
                        synchronizedFolder: .init(
                            path: "App/Sources",
                            targets: synchronizedFolders
                        )
                    ),
                ]
            ),
        ]

        let pathTree = Generator.calculatePathTree(
            paths: paths,
            generatedPaths: generatedPaths,
            synchronizedFolders: synchronizedFolders
        )

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }

    func test_synchronizedFolder_reanchorsGeneratedPackagesWithinFolder() {
        let paths: [BazelPath] = []
        let generatedPaths: [GeneratedPath] = [
            .init(
                config: "darwin_arm64-dbg",
                package: "App",
                path: "rules_xcodeproj/App/Info.plist"
            ),
            .init(
                config: "darwin_arm64-dbg",
                package: "App/EditorExtension",
                path: "rules_xcodeproj/EditorExtension/Info.plist"
            ),
        ]
        let synchronizedFolders: [SynchronizedFolderTarget] = [
            .init(
                folderPath: "App",
                targetIdentifier: "TARGET /* App */",
                targetName: "App",
                includedPaths: ["App/Sources/App.swift"],
                excludedPaths: []
            )
        ]

        let expectedPathTree: [PathTreeNode] = [
            .generatedFiles(.singleConfig(
                path: "darwin_arm64-dbg/bin",
                children: [
                    .group(
                        name: "App",
                        children: [
                            .group(
                                name: "EditorExtension",
                                children: [
                                    .group(
                                        name: "rules_xcodeproj",
                                        children: [
                                            .group(
                                                name: "EditorExtension",
                                                children: [
                                                    .file("Info.plist"),
                                                ]
                                            ),
                                        ]
                                    ),
                                ]
                            ),
                            .group(
                                name: "rules_xcodeproj",
                                children: [
                                    .group(
                                        name: "App",
                                        children: [
                                            .file("Info.plist"),
                                        ]
                                    ),
                                ]
                            ),
                        ]
                    ),
                ]
            )),
            .synchronizedGroup(
                name: "App",
                synchronizedFolder: .init(
                    path: "App",
                    targets: synchronizedFolders
                )
            ),
        ]

        let pathTree = Generator.calculatePathTree(
            paths: paths,
            generatedPaths: generatedPaths,
            synchronizedFolders: synchronizedFolders
        )

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }

    func test_nestedSynchronizedFolders_areHiddenUnderVisibleAncestor() {
        let paths: [BazelPath] = []
        let generatedPaths: [GeneratedPath] = [
            .init(
                config: "darwin_arm64-dbg",
                package: "App",
                path: "rules_xcodeproj/App/Info.plist"
            ),
            .init(
                config: "darwin_arm64-dbg",
                package: "App/OnboardingResources",
                path: "Generated.swift"
            ),
            .init(
                config: "darwin_arm64-dbg",
                package: "App/UITests",
                path: "rules_xcodeproj/UITests/Info.plist"
            ),
        ]
        let synchronizedFolders: [SynchronizedFolderTarget] = [
            .init(
                folderPath: "App",
                targetIdentifier: "TARGET /* App */",
                targetName: "App",
                includedPaths: ["App/Sources/App.swift"],
                excludedPaths: []
            ),
            .init(
                folderPath: "App/OnboardingResources",
                targetIdentifier: "TARGET /* OnboardingResources */",
                targetName: "OnboardingResources",
                includedPaths: ["App/OnboardingResources/Generated.swift"],
                excludedPaths: []
            ),
        ]

        let expectedPathTree: [PathTreeNode] = [
            .generatedFiles(.singleConfig(
                path: "darwin_arm64-dbg/bin",
                children: [
                    .group(
                        name: "App",
                        children: [
                            .group(
                                name: "OnboardingResources",
                                children: [
                                    .file("Generated.swift"),
                                ]
                            ),
                            .group(
                                name: "UITests",
                                children: [
                                    .group(
                                        name: "rules_xcodeproj",
                                        children: [
                                            .group(
                                                name: "UITests",
                                                children: [
                                                    .file("Info.plist"),
                                                ]
                                            ),
                                        ]
                                    ),
                                ]
                            ),
                            .group(
                                name: "rules_xcodeproj",
                                children: [
                                    .group(
                                        name: "App",
                                        children: [
                                            .file("Info.plist"),
                                        ]
                                    ),
                                ]
                            ),
                        ]
                    ),
                ]
            )),
            .synchronizedGroup(
                name: "App",
                synchronizedFolder: .init(
                    path: "App",
                    targets: [
                        synchronizedFolders[0],
                    ]
                )
            ),
        ]

        let pathTree = Generator.calculatePathTree(
            paths: paths,
            generatedPaths: generatedPaths,
            synchronizedFolders: synchronizedFolders
        )

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }

    func test_synchronizedFolders_promoteSharedDependencyBranchRoots() {
        let paths: [BazelPath] = []
        let generatedPaths: [GeneratedPath] = []
        let synchronizedFolders: [SynchronizedFolderTarget] = [
            .init(
                folderPath: "iosapp/Apps/Graff/Sources",
                targetIdentifier: "TARGET /* Graff */",
                targetName: "Graff",
                includedPaths: ["iosapp/Apps/Graff/Sources/App.swift"],
                excludedPaths: []
            ),
            .init(
                folderPath: "iosapp/Components/AlertDialog/API",
                targetIdentifier: "TARGET /* AlertDialog */",
                targetName: "AlertDialog",
                includedPaths: ["iosapp/Components/AlertDialog/API/Sources/AlertDialog.swift"],
                excludedPaths: []
            ),
            .init(
                folderPath: "iosapp/Components/AppShell/API",
                targetIdentifier: "TARGET /* AppShell */",
                targetName: "AppShell",
                includedPaths: ["iosapp/Components/AppShell/API/Sources/AppShell.swift"],
                excludedPaths: []
            ),
        ]

        let expectedPathTree: [PathTreeNode] = [
            .group(
                name: "iosapp",
                children: [
                    .group(
                        name: "Apps",
                        children: [
                            .group(
                                name: "Graff",
                                children: [
                                    .synchronizedGroup(
                                        name: "Sources",
                                        synchronizedFolder: .init(
                                            path: "iosapp/Apps/Graff/Sources",
                                            targets: [
                                                synchronizedFolders[0],
                                            ]
                                        )
                                    ),
                                ]
                            ),
                        ]
                    ),
                    .synchronizedGroup(
                        name: "Components",
                        synchronizedFolder: .init(
                            path: "iosapp/Components",
                            targets: []
                        )
                    ),
                ]
            ),
        ]

        let pathTree = Generator.calculatePathTree(
            paths: paths,
            generatedPaths: generatedPaths,
            synchronizedFolders: synchronizedFolders
        )

        XCTAssertNoDifference(pathTree, expectedPathTree)
    }
}
