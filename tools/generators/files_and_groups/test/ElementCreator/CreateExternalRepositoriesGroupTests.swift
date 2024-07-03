import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateExternalRepositoriesGroupTests: XCTestCase {
    func test() {
        // Arrange

        let name = "bazel-out"
        let nodeChildren: [PathTreeNode] = [
            .file(name: "a"),
            .group(
                name: "b.lproj",
                children: [
                    .file(name: "y"),
                    .group(
                        name: "z.ext",
                        children: [.file(name: "other")]
                    ),
                ]
            ),
        ]
        let bazelPathType = BazelPathType.legacyBazelExternal

        let expectedBazelPath: BazelPath = "bazel-out"

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
        let stubbedGroupChildren: [GroupChild] = [
            .elementAndChildren(.init(
                element: .init(
                    name: "a",
                    object: .init(
                        identifier: "a id",
                        content: "a content"
                    ),
                    sortOrder: .groupLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "a id",
                        content: "a content"
                    )
                ],
                bazelPathAndIdentifiers: [("bazel-out/a", "a id")],
                knownRegions: ["enGB", "frCA"],
                resolvedRepositories: [
                    ResolvedRepository(sourcePath: "a", mappedPath: "2"),
                ]
            )),
            .localizedRegion([
                GroupChild.LocalizedFile(
                    element: .init(
                        name: "y",
                        object: .init(
                            identifier: "y id",
                            content: "y content"
                        ),
                        sortOrder: .fileLike
                    ),
                    region: "b",
                    name: "y",
                    basenameWithoutExt: "y",
                    ext: nil,
                    bazelPaths: ["bazel-out/b.lproj/y"]
                ),
                GroupChild.LocalizedFile(
                    element: .init(
                        name: "z",
                        object: .init(
                            identifier: "z id",
                            content: "z content"
                        ),
                        sortOrder: .fileLike
                    ),
                    region: "b",
                    name: "z",
                    basenameWithoutExt: "z",
                    ext: "ext",
                    bazelPaths: [
                        "bazel-out/b.lproj/z.ext/other",
                        "bazel-out/b.lproj/z.ext",
                    ]
                ),
            ])
        ]
        let createGroupChild = ElementCreator.CreateGroupChild
            .mock(children: stubbedGroupChildren)

        let expectedCreateGroupChildElementsCalled: [
            ElementCreator.CreateGroupChildElements.MockTracker.Called
        ] = [
            .init(
                parentBazelPath: expectedBazelPath,
                groupChildren: stubbedGroupChildren,
                resolvedRepositories: []
            )
        ]
        let stubbedGroupChildElements = GroupChildElements(
            elements: [
                .init(
                    name: "a",
                    object: .init(
                        identifier: "a id",
                        content: "a content"
                    ),
                    sortOrder: .groupLike
                ),
                .init(
                    name: "y",
                    object: .init(
                        identifier: "y id",
                        content: "y content"
                    ),
                    sortOrder: .fileLike
                ),
                .init(
                    name: "z",
                    object: .init(
                        identifier: "z id",
                        content: "z content"
                    ),
                    sortOrder: .fileLike
                ),
            ],
            transitiveObjects: [
                .init(
                    identifier: "a id",
                    content: "a content"
                ),
                .init(
                    identifier: "y id",
                    content: "y content"
                ),
                .init(
                    identifier: "z id",
                    content: "z content"
                ),
            ],
            bazelPathAndIdentifiers: [
                ("bazel-out/a", "a id"),
                ("bazel-out/b.lproj/y", "y id"),
                ("bazel-out/b.lproj/z.ext/other", "z id"),
                ("bazel-out/b.lproj/z.ext", "z id"),
            ],
            knownRegions: ["enGB", "frCA", "b"],
            resolvedRepositories: [
                ResolvedRepository(sourcePath: "a", mappedPath: "2"),
                ResolvedRepository(sourcePath: "y", mappedPath: "1"),
                ResolvedRepository(sourcePath: "z", mappedPath: "3"),
            ]
        )
        let createGroupChildElements = ElementCreator.CreateGroupChildElements
            .mock(groupChildElements: stubbedGroupChildElements)

        let stubbedElement = Element(
            name: "Generated",
            object: .init(
                identifier: "Generated ID",
                content: "Generated Content"
            ),
            sortOrder: .groupLike
        )
        let expectedCreateExternalRepositoriesGroupElementCalled: [
            ElementCreator.CreateExternalRepositoriesGroupElement.MockTracker.Called
        ] = [
            .init(
                childIdentifiers:
                    stubbedGroupChildElements.elements.map(\.object.identifier)
            )
        ]
        let createExternalRepositoriesGroupElement =
            ElementCreator.CreateExternalRepositoriesGroupElement
                .mock(element: stubbedElement)

        let expectedResult = GroupChild.ElementAndChildren(
            bazelPath: expectedBazelPath,
            element: stubbedElement,
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: nil,
            children: stubbedGroupChildElements
        )

        // Act

        let result = ElementCreator.CreateExternalRepositoriesGroup
            .defaultCallable(
                name: name,
                nodeChildren: nodeChildren,
                bazelPathType: bazelPathType,
                createExternalRepositoriesGroupElement:
                    createExternalRepositoriesGroupElement.mock,
                createGroupChild: createGroupChild.mock,
                createGroupChildElements: createGroupChildElements.mock
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
            createExternalRepositoriesGroupElement.tracker.called,
            expectedCreateExternalRepositoriesGroupElementCalled
        )
        XCTAssertNoDifference(result, expectedResult)
    }
}
