import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateRootElementsTests: XCTestCase {
    func test() {
        // Arrange

        let pathTree = PathTreeNode(
            name: "",
            children: [
                PathTreeNode(
                    name: "bazel-out",
                    children: [
                        PathTreeNode(name: "1"),
                        PathTreeNode(name: "2"),
                    ]
                ),
                PathTreeNode(name: "a"),
                PathTreeNode(
                    name: "..",
                    children: [
                        PathTreeNode(name: "3"),
                    ]
                ),
                PathTreeNode(name: "b"),
                PathTreeNode(
                    name: "external",
                    children: [
                        PathTreeNode(name: "4"),
                    ]
                ),
            ]
        )
        let installPath = "a/visonary.xcodeproj"
        let workspace = "/Users/TimApple/Star Board"
        let includeCompileStub = true

        let expectedResolvedRepositories: [ResolvedRepository] = [
            .init(sourcePath: ".", mappedPath: workspace)
        ]

        let expectedCreateSpecialRootGroupCalled: [
            ElementCreator.CreateSpecialRootGroup.MockTracker.Called
        ] = [
            .init(
                node: pathTree.children[0],
                specialRootGroupType: .bazelGenerated
            ),
            .init(
                node: pathTree.children[2],
                specialRootGroupType: .siblingBazelExternal
            ),
            .init(
                node: pathTree.children[4],
                specialRootGroupType: .legacyBazelExternal
            ),
        ]
        let stubbedSpecialRootGroupChildElementAndChildren = [
            GroupChild.ElementAndChildren(
                element: .init(
                    name: "bazel-out",
                    object: .init(
                        identifier: "bazel-out id",
                        content: "bazel-out content"
                    ),
                    sortOrder: .groupLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "1 id",
                        content: "1 content"
                    ),
                    .init(
                        identifier: "2 id",
                        content: "2 content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    ("bazel-out/1", "1 id"),
                    ("bazel-out/2", "2 id"),
                ],
                knownRegions: ["bazel-out region"],
                resolvedRepositories: [.init(sourcePath: "z", mappedPath: "z")]
            ),
            GroupChild.ElementAndChildren(
                element: .init(
                    name: "sibling",
                    object: .init(
                        identifier: "sibling id",
                        content: "sibling content"
                    ),
                    sortOrder: .groupLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "3 id",
                        content: "3 content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    ("../3", "3 id"),
                ],
                knownRegions: ["sibling region"],
                resolvedRepositories: [.init(sourcePath: "y", mappedPath: "y")]
            ),
            GroupChild.ElementAndChildren(
                element: .init(
                    name: "legacy",
                    object: .init(
                        identifier: "legacy id",
                        content: "legacy content"
                    ),
                    sortOrder: .groupLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "4 id",
                        content: "4 content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    ("external/4", "4 id"),
                ],
                knownRegions: ["external region"],
                resolvedRepositories: [.init(sourcePath: "x", mappedPath: "x")]
            ),
        ]
        let createSpecialRootGroup = ElementCreator.CreateSpecialRootGroup.mock(
            groupChildElements: stubbedSpecialRootGroupChildElementAndChildren
        )

        let expectedCreateGroupChildCalled: [
            ElementCreator.CreateGroupChild.MockTracker.Called
        ] = [
            .init(
                node: pathTree.children[1],
                parentBazelPath: "",
                specialRootGroupType: nil
            ),
            .init(
                node: pathTree.children[3],
                parentBazelPath: "",
                specialRootGroupType: nil
            ),
        ]
        let stubbedGroupChildElementAndChildren = [
            GroupChild.ElementAndChildren(
                element: .init(
                    name: "a",
                    object: .init(
                        identifier: "a identifier",
                        content: "a content"
                    ),
                    sortOrder: .fileLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "a/inner identifier",
                        content: "a/inner content"
                    ),
                    .init(
                        identifier: "a identifier",
                        content: "a content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    ("node_name.some_ext/a/i", "a/inner identifier"),
                    ("node_name.some_ext/a", "a identifier"),
                ],
                knownRegions: ["a region"],
                resolvedRepositories: [.init(sourcePath: "a", mappedPath: "a")]
            ),
            GroupChild.ElementAndChildren(
                element: .init(
                    name: "b",
                    object: .init(
                        identifier: "b identifier",
                        content: "b content"
                    ),
                    sortOrder: .fileLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "b identifier",
                        content: "b content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    ("node_name.some_ext/b", "b identifier"),
                ],
                knownRegions: ["b region"],
                resolvedRepositories: [.init(sourcePath: "b", mappedPath: "b")]
            ),
        ]
        let stubbedCreateGroupChildResults: [GroupChild] = [
            .elementAndChildren(stubbedGroupChildElementAndChildren[0]),
            .elementAndChildren(stubbedGroupChildElementAndChildren[1]),
        ]
        let createGroupChild = ElementCreator.CreateGroupChild.mock(
            children: stubbedCreateGroupChildResults
        )

        let expectedCreateInternalGroupCalled: [
            ElementCreator.CreateInternalGroup.MockTracker.Called
        ] = [
            .init(installPath: installPath),
        ]
        let stubbedInternalGroup = GroupChild.elementAndChildren(.init(
            element: .init(
                name: "rules_xcodeproj",
                object: .init(
                    identifier: "r_xcp_id",
                    content: "{INTERNAL}"
                ),
                sortOrder: .rulesXcodeprojInternal
            ),
            transitiveObjects: [],
            bazelPathAndIdentifiers:[],
            knownRegions: [],
            resolvedRepositories: []
        ))
        let createInternalGroup = ElementCreator.CreateInternalGroup
            .mock(groupChildren: [stubbedInternalGroup])

        let expectedCreateGroupChildElementsCalled: [
            ElementCreator.CreateGroupChildElements.MockTracker.Called
        ] = [
            .init(
                parentBazelPath: "",
                groupChildren: [
                    .elementAndChildren(
                        stubbedSpecialRootGroupChildElementAndChildren[0]
                    ),
                    stubbedCreateGroupChildResults[0],
                    .elementAndChildren(
                        stubbedSpecialRootGroupChildElementAndChildren[1]
                    ),
                    stubbedCreateGroupChildResults[1],
                    .elementAndChildren(
                        stubbedSpecialRootGroupChildElementAndChildren[2]
                    ),
                    stubbedInternalGroup,
                ],
                resolvedRepositories: expectedResolvedRepositories
            )
        ]
        let stubbedRootElements = GroupChildElements(
            elements: [
                stubbedSpecialRootGroupChildElementAndChildren[0].element,
                stubbedGroupChildElementAndChildren[0].element,
                stubbedSpecialRootGroupChildElementAndChildren[1].element,
                stubbedGroupChildElementAndChildren[1].element,
                stubbedSpecialRootGroupChildElementAndChildren[2].element,
            ],
            transitiveObjects: [
                stubbedSpecialRootGroupChildElementAndChildren[0]
                    .transitiveObjects[0],
                stubbedSpecialRootGroupChildElementAndChildren[0]
                    .transitiveObjects[1],
                stubbedGroupChildElementAndChildren[0].transitiveObjects[0],
                stubbedSpecialRootGroupChildElementAndChildren[1]
                    .transitiveObjects[0],
                stubbedGroupChildElementAndChildren[0].transitiveObjects[1],
                stubbedSpecialRootGroupChildElementAndChildren[2]
                    .transitiveObjects[0],
                stubbedGroupChildElementAndChildren[1].transitiveObjects[0],
            ],
            bazelPathAndIdentifiers: [
                stubbedSpecialRootGroupChildElementAndChildren[0]
                    .bazelPathAndIdentifiers[0],
                stubbedSpecialRootGroupChildElementAndChildren[0]
                    .bazelPathAndIdentifiers[1],
                stubbedGroupChildElementAndChildren[0]
                    .bazelPathAndIdentifiers[0],
                stubbedGroupChildElementAndChildren[0]
                    .bazelPathAndIdentifiers[1],
                stubbedSpecialRootGroupChildElementAndChildren[1]
                    .bazelPathAndIdentifiers[0],
                stubbedGroupChildElementAndChildren[1]
                    .bazelPathAndIdentifiers[0],
                stubbedSpecialRootGroupChildElementAndChildren[2]
                    .bazelPathAndIdentifiers[0],
            ],
            knownRegions: stubbedGroupChildElementAndChildren[0].knownRegions
                .union(stubbedGroupChildElementAndChildren[1].knownRegions)
                .union(stubbedSpecialRootGroupChildElementAndChildren[0].knownRegions)
                .union(stubbedSpecialRootGroupChildElementAndChildren[1].knownRegions)
                .union(stubbedSpecialRootGroupChildElementAndChildren[2].knownRegions),
            resolvedRepositories: [
                stubbedSpecialRootGroupChildElementAndChildren[0]
                    .resolvedRepositories[0],
                stubbedGroupChildElementAndChildren[0].resolvedRepositories[0],
                stubbedSpecialRootGroupChildElementAndChildren[1]
                    .resolvedRepositories[0],
                stubbedGroupChildElementAndChildren[1].resolvedRepositories[0],
                stubbedSpecialRootGroupChildElementAndChildren[2]
                    .resolvedRepositories[0],
                ResolvedRepository(sourcePath: ".", mappedPath: "SRCROOT"),
            ]
        )
        let createGroupChildElements = ElementCreator.CreateGroupChildElements
            .mock(groupChildElements: stubbedRootElements)

        // Act

        let rootElements = ElementCreator.CreateRootElements.defaultCallable(
            for: pathTree,
            includeCompileStub: includeCompileStub,
            installPath: installPath,
            workspace: workspace,
            createGroupChild: createGroupChild.mock,
            createGroupChildElements: createGroupChildElements.mock,
            createInternalGroup: createInternalGroup.mock,
            createSpecialRootGroup: createSpecialRootGroup.mock
        )

        // Assert

        XCTAssertNoDifference(
            createGroupChild.tracker.called,
            expectedCreateGroupChildCalled
        )
        XCTAssertNoDifference(
            createGroupChildElements.tracker.called,
            expectedCreateGroupChildElementsCalled
        )
        XCTAssertNoDifference(
            createInternalGroup.tracker.called,
            expectedCreateInternalGroupCalled
        )
        XCTAssertNoDifference(
            createSpecialRootGroup.tracker.called,
            expectedCreateSpecialRootGroupCalled
        )
        XCTAssertNoDifference(rootElements, stubbedRootElements)
    }
}
