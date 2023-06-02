import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateSpecialRootGroupTests: XCTestCase {
    func test() {
        // Arrange

        let node = PathTreeNode(
            name: "bazel-out",
            children: [
                PathTreeNode(name: "a"),
                PathTreeNode(
                    name: "b.lproj",
                    children: [
                        PathTreeNode(name: "y"),
                        PathTreeNode(
                            name: "z.ext",
                            children: [PathTreeNode(name: "other")]
                        ),
                    ]
                ),
            ]
        )
        let specialRootGroupType = SpecialRootGroupType.legacyBazelExternal

        let expectedBazelPath: BazelPath = "bazel-out"

        let expectedCreateGroupChildCalled: [
            ElementCreator.CreateGroupChild.MockTracker.Called
        ] = [
            .init(
                node: node.children[0],
                parentBazelPath: expectedBazelPath,
                specialRootGroupType: specialRootGroupType
            ),
            .init(
                node: node.children[1],
                parentBazelPath: expectedBazelPath,
                specialRootGroupType: specialRootGroupType
            ),
        ]
        let stubbedGroupChildren: [GroupChild] = [
            .elementAndChildren(.init(
                element: Element(
                    name: "a",
                    identifier: "a id",
                    content: "a content",
                    sortOrder: .groupLike
                ),
                transitiveElements: [
                    Element(
                        name: "a",
                        identifier: "a id",
                        content: "a content",
                        sortOrder: .groupLike
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
                    element: Element(
                        name: "y",
                        identifier: "y id",
                        content: "y content",
                        sortOrder: .fileLike
                    ),
                    region: "b",
                    name: "y",
                    basenameWithoutExt: "y",
                    ext: nil,
                    bazelPaths: ["bazel-out/b.lproj/y"]
                ),
                GroupChild.LocalizedFile(
                    element: Element(
                        name: "z",
                        identifier: "z id",
                        content: "z content",
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
                Element(
                    name: "a",
                    identifier: "a id",
                    content: "a content",
                    sortOrder: .groupLike
                ),
                Element(
                    name: "y",
                    identifier: "y id",
                    content: "y content",
                    sortOrder: .fileLike
                ),
                Element(
                    name: "z",
                    identifier: "z id",
                    content: "z content",
                    sortOrder: .fileLike
                ),
            ],
            transitiveElements: [
                Element(
                    name: "a",
                    identifier: "a id",
                    content: "a content",
                    sortOrder: .groupLike
                ),
                Element(
                    name: "y",
                    identifier: "y id",
                    content: "y content",
                    sortOrder: .fileLike
                ),
                Element(
                    name: "z",
                    identifier: "z id",
                    content: "z content",
                    sortOrder: .fileLike
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
            identifier: "Generated ID",
            content: "Generated Content",
            sortOrder: .groupLike
        )
        let expectedCreateSpecialRootGroupElementCalled: [
            ElementCreator.CreateSpecialRootGroupElement.MockTracker.Called
        ] = [
            .init(
                specialRootGroupType: specialRootGroupType,
                childIdentifiers:
                    stubbedGroupChildElements.elements.map(\.identifier)
            )
        ]
        let createSpecialRootGroupElement =
            ElementCreator.CreateSpecialRootGroupElement
                .mock(element: stubbedElement)

        let expectedResult = GroupChild.ElementAndChildren(
            bazelPath: expectedBazelPath,
            element: stubbedElement,
            resolvedRepository: nil,
            children: stubbedGroupChildElements
        )

        // Act

        let result = ElementCreator.CreateSpecialRootGroup.defaultCallable(
            for: node,
            specialRootGroupType: specialRootGroupType,
            createGroupChild: createGroupChild.mock,
            createGroupChildElements: createGroupChildElements.mock,
            createSpecialRootGroupElement: createSpecialRootGroupElement.mock
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
            createSpecialRootGroupElement.tracker.called,
            expectedCreateSpecialRootGroupElementCalled
        )
        XCTAssertNoDifference(result, expectedResult)
    }
}
