import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateGroupTests: XCTestCase {
    func test() {
        // Arrange

        let name = "node_name.some_ext"
        let nodeChildren: [PathTreeNode] = [
            .file("a"),
            .file("b"),
        ]
        let parentBazelPath: BazelPath = "bazel/path"
        let bazelPathType = BazelPathType.siblingBazelExternal

        let expectedBazelPath: BazelPath = "bazel/path/node_name.some_ext"

        let expectedCreateGroupChildCalled: [
            ElementCreator.CreateGroupChild.MockTracker.Called
        ] = [
            .init(
                node: nodeChildren[0],
                parentBazelPath: expectedBazelPath,
                parentBazelPathType: bazelPathType
            ),
            .init(
                node: nodeChildren[1],
                parentBazelPath: expectedBazelPath,
                parentBazelPathType: bazelPathType
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
                    ("bazel/path/node_name.some_ext/a/i", "a/inner identifier"),
                    ("bazel/path/node_name.some_ext/a", "a identifier"),
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
                    ("bazel/path/node_name.some_ext/b", "b identifier"),
                ],
                knownRegions: ["b region"],
                resolvedRepositories: [.init(sourcePath: "b", mappedPath: "b")]
            ),
        ]
        let stubbedChildren: [GroupChild] = [
            .elementAndChildren(stubbedGroupChildElementAndChildren[0]),
            .elementAndChildren(stubbedGroupChildElementAndChildren[1]),
        ]
        let createGroupChild = ElementCreator.CreateGroupChild
            .mock(children: stubbedChildren)

        let expectedCreateGroupChildElementsCalled: [
            ElementCreator.CreateGroupChildElements.MockTracker.Called
        ] = [
            .init(
                parentBazelPath: expectedBazelPath,
                groupChildren: stubbedChildren,
                resolvedRepositories: []
            ),
        ]
        let stubbedGroupChildElements = GroupChildElements(
            elements: [
                stubbedGroupChildElementAndChildren[0].element,
                stubbedGroupChildElementAndChildren[1].element,
            ],
            transitiveObjects: [
                stubbedGroupChildElementAndChildren[0].transitiveObjects[0],
                stubbedGroupChildElementAndChildren[0].transitiveObjects[1],
                stubbedGroupChildElementAndChildren[1].transitiveObjects[0],
            ],
            bazelPathAndIdentifiers: [
                stubbedGroupChildElementAndChildren[0]
                    .bazelPathAndIdentifiers[0],
                stubbedGroupChildElementAndChildren[0]
                    .bazelPathAndIdentifiers[1],
                stubbedGroupChildElementAndChildren[1]
                    .bazelPathAndIdentifiers[0],
            ],
            knownRegions: stubbedGroupChildElementAndChildren[0].knownRegions
                .union(stubbedGroupChildElementAndChildren[1].knownRegions),
            resolvedRepositories: [
                stubbedGroupChildElementAndChildren[0].resolvedRepositories[0],
                stubbedGroupChildElementAndChildren[1].resolvedRepositories[0],
            ]
        )
        let createGroupChildElements = ElementCreator.CreateGroupChildElements
            .mock(groupChildElements: stubbedGroupChildElements)

        let expectedCreateGroupElementCalled: [
            ElementCreator.CreateGroupElement.MockTracker.Called
        ] = [
            .init(
                name: name,
                bazelPath: expectedBazelPath,
                bazelPathType: bazelPathType,
                childIdentifiers: [
                    stubbedGroupChildElementAndChildren[0]
                        .element.object.identifier,
                    stubbedGroupChildElementAndChildren[1]
                        .element.object.identifier,
                ]
            )
        ]
        let stubbedElement = Element(
            name: "name",
            object: .init(
                identifier: "identifier",
                content: "content"
            ),
            sortOrder: .groupLike
        )
        let stubbedResolvedRepository = ResolvedRepository(
            sourcePath: "source",
            mappedPath: "mapped"
        )
        let createGroupElement = ElementCreator.CreateGroupElement.mock(
            element: stubbedElement,
            resolvedRepository: stubbedResolvedRepository
        )

        let expectedResult = GroupChild.ElementAndChildren(
            element: stubbedElement,
            transitiveObjects: stubbedGroupChildElements.transitiveObjects +
                [stubbedElement.object],
            bazelPathAndIdentifiers:
                stubbedGroupChildElements.bazelPathAndIdentifiers,
            knownRegions: stubbedGroupChildElements.knownRegions,
            resolvedRepositories:
                stubbedGroupChildElements.resolvedRepositories +
                    [stubbedResolvedRepository]
        )

        // Act

        let result = ElementCreator.CreateGroup.defaultCallable(
            name: name,
            nodeChildren: nodeChildren,
            parentBazelPath: parentBazelPath,
            bazelPathType: bazelPathType,
            createGroupChild: createGroupChild.mock,
            createGroupChildElements: createGroupChildElements.mock,
            createGroupElement: createGroupElement.mock
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
            createGroupElement.tracker.called,
            expectedCreateGroupElementCalled
        )
        XCTAssertNoDifference(result, expectedResult)
    }
}
