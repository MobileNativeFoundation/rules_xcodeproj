import CustomDump
import PBXProj
import ToolCommon
import XCTest

@testable import files_and_groups

final class CreateRootElementsTests: XCTestCase {
    func test() throws {
        // Arrange

        let pathTree: [PathTreeNode] = [
            .generatedFiles(.multipleConfigs([
                .init(
                    name: "config2",
                    path: "config2/bin",
                    children: [
                        .file(name: "gen"),
                    ]
                ),
                .init(
                    name: "config1",
                    path: "config1/bin",
                    children: [
                        .file(name: "gen"),
                    ]
                ),
            ])),
            .file(name: "a"),
            .group(
                name: "..",
                children: [
                    .generatedFiles(.singleConfig(
                        path: "config3/bin/external/something~",
                        children: [
                            .group(
                                name: "gen",
                                children: [
                                    .file(name: "a"),
                                ]
                            ),
                        ]
                    )),
                    .file(name: "3"),
                ]
            ),
            .file(name: "b"),
            .group(
                name: "external",
                children: [
                    .file(name: "4"),
                ]
            ),
        ]
        let installPath = "a/visonary.xcodeproj"
        let workspace = "/Users/TimApple/Star Board"
        let includeCompileStub = true

        let expectedResolvedRepositories: [ResolvedRepository] = [
            .init(sourcePath: ".", mappedPath: workspace)
        ]

        let expectedCreateExternalRepositoriesGroupCalled: [
            ElementCreator.CreateExternalRepositoriesGroup.MockTracker.Called
        ] = [
            .init(
                name: try pathTree[2].groupName,
                nodeChildren: try pathTree[2].groupChildren,
                bazelPathType: .siblingBazelExternal
            ),
            .init(
                name: try pathTree[4].groupName,
                nodeChildren: try pathTree[4].groupChildren,
                bazelPathType: .legacyBazelExternal
            ),
        ]
        let stubbedExternalRepositoriesGroupChildElementAndChildren = [
            GroupChild.ElementAndChildren(
                element: .init(
                    name: "sibling",
                    object: .init(
                        identifier: "sibling id",
                        content: "sibling content"
                    ),
                    sortOrder: .bazelExternalRepositories
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
        let createExternalRepositoriesGroup =
            ElementCreator.CreateExternalRepositoriesGroup.mock(
                groupChildElements:
                    stubbedExternalRepositoriesGroupChildElementAndChildren
            )

        let expectedCreateGroupChildCalled: [
            ElementCreator.CreateGroupChild.MockTracker.Called
        ] = [
            .init(
                node: pathTree[0],
                parentBazelPath: "",
                parentBazelPathType: .workspace
            ),
            .init(
                node: pathTree[1],
                parentBazelPath: "",
                parentBazelPathType: .workspace
            ),
            .init(
                node: pathTree[3],
                parentBazelPath: "",
                parentBazelPathType: .workspace
            ),
        ]
        let stubbedGroupChildElementAndChildren = [
            GroupChild.ElementAndChildren(
                element: .init(
                    name: "Bazel Generated",
                    object: .init(
                        identifier: "Bazel Generated identifier",
                        content: "Bazel Generated content"
                    ),
                    sortOrder: .inlineBazelGenerated
                ),
                transitiveObjects: [
                    .init(
                        identifier: "bazel-out/c2 identifier",
                        content: "bazel-out/c2 content"
                    ),
                    .init(
                        identifier: "bazel-out/c1 identifier",
                        content: "bazel-out/c1 content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    ("bazel-out/config2/bin/gen", "bazel-out/c2 identifier"),
                    ("bazel-out/config1/bin/gen", "bazel-out/c1 identifier"),
                ],
                knownRegions: ["a region"],
                resolvedRepositories: [.init(sourcePath: "b", mappedPath: "b")]
            ),
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
            .elementAndChildren(stubbedGroupChildElementAndChildren[2]),
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
                    stubbedCreateGroupChildResults[0],
                    stubbedCreateGroupChildResults[1],
                    .elementAndChildren(
                        stubbedExternalRepositoriesGroupChildElementAndChildren[0]
                    ),
                    stubbedCreateGroupChildResults[2],
                    .elementAndChildren(
                        stubbedExternalRepositoriesGroupChildElementAndChildren[1]
                    ),
                    stubbedInternalGroup,
                ],
                resolvedRepositories: expectedResolvedRepositories
            )
        ]
        let stubbedRootElements = GroupChildElements(
            elements: [
                stubbedGroupChildElementAndChildren[0].element,
                stubbedGroupChildElementAndChildren[1].element,
                stubbedExternalRepositoriesGroupChildElementAndChildren[0].element,
                stubbedGroupChildElementAndChildren[2].element,
                stubbedExternalRepositoriesGroupChildElementAndChildren[1].element,
            ],
            transitiveObjects: [
                stubbedGroupChildElementAndChildren[0].transitiveObjects[0],
                stubbedExternalRepositoriesGroupChildElementAndChildren[0]
                    .transitiveObjects[0],
                stubbedGroupChildElementAndChildren[0].transitiveObjects[1],
                stubbedExternalRepositoriesGroupChildElementAndChildren[1]
                    .transitiveObjects[0],
                stubbedGroupChildElementAndChildren[1].transitiveObjects[0],
            ],
            bazelPathAndIdentifiers: [
                stubbedGroupChildElementAndChildren[0]
                    .bazelPathAndIdentifiers[0],
                stubbedGroupChildElementAndChildren[0]
                    .bazelPathAndIdentifiers[1],
                stubbedExternalRepositoriesGroupChildElementAndChildren[0]
                    .bazelPathAndIdentifiers[0],
                stubbedGroupChildElementAndChildren[1]
                    .bazelPathAndIdentifiers[0],
                stubbedExternalRepositoriesGroupChildElementAndChildren[1]
                    .bazelPathAndIdentifiers[0],
            ],
            knownRegions: stubbedGroupChildElementAndChildren[0].knownRegions
                .union(stubbedGroupChildElementAndChildren[1].knownRegions)
                .union(stubbedExternalRepositoriesGroupChildElementAndChildren[0].knownRegions)
                .union(stubbedExternalRepositoriesGroupChildElementAndChildren[1].knownRegions),
            resolvedRepositories: [
                stubbedGroupChildElementAndChildren[0].resolvedRepositories[0],
                stubbedExternalRepositoriesGroupChildElementAndChildren[0]
                    .resolvedRepositories[0],
                stubbedGroupChildElementAndChildren[1].resolvedRepositories[0],
                stubbedExternalRepositoriesGroupChildElementAndChildren[1]
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
            createExternalRepositoriesGroup:
                createExternalRepositoriesGroup.mock,
            createGroupChild: createGroupChild.mock,
            createGroupChildElements: createGroupChildElements.mock,
            createInternalGroup: createInternalGroup.mock
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
            createExternalRepositoriesGroup.tracker.called,
            expectedCreateExternalRepositoriesGroupCalled
        )
        XCTAssertNoDifference(rootElements, stubbedRootElements)
    }
}

private extension PathTreeNode {
    var groupChildren: [PathTreeNode] {
        get throws {
            switch self {
            case .group(_, let children):
                return children
            default:
                throw PreconditionError(message: "Invalid node type")
            }
        }
    }

    var groupName: String {
        get throws {
            switch self {
            case .group(let name, _):
                return name
            default:
                throw PreconditionError(message: "Invalid node type")
            }
        }
    }
}
