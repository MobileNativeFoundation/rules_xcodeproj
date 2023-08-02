import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateVersionGroupTests: XCTestCase {
    func test() {
        // Arrange

        let node = PathTreeNode(
            name: "node.xcdatamodeld",
            children: [
                PathTreeNode(name: "weird"),
                PathTreeNode(name: "a.xcdatamodel"),
                PathTreeNode(
                    name: "b.xcdatamodel",
                    children: [
                        PathTreeNode(name: "odd"),
                    ]
                ),
                PathTreeNode(name: "c.xcdatamodel"),
            ]
        )
        let parentBazelPath: BazelPath = "bazel/path"
        let specialRootGroupType = SpecialRootGroupType.legacyBazelExternal

        let expectedBazelPath: BazelPath = "bazel/path/node.xcdatamodeld"

        let selectedModelVersions: [BazelPath: String] = [
            "another/a.xcdatamodeld": "other.xcdatamodel",
            expectedBazelPath: "b.xcdatamodel",
        ]

        let expectedCreateIdentifierCalled: [
            ElementCreator.CreateIdentifier.MockTracker.Called
        ] = [
            .init(path: expectedBazelPath.path, type: .coreData),
        ]
        let stubbedIdentifier = "identifier"
        let createIdentifier = ElementCreator.CreateIdentifier
            .mock(identifier: stubbedIdentifier)

        let expectedCreateFileCalled: [
            ElementCreator.CreateFile.MockTracker.Called
        ] = [
            .init(
                node: node.children[0],
                bazelPath: expectedBazelPath + node.children[0],
                specialRootGroupType: specialRootGroupType,
                identifierForBazelPaths: stubbedIdentifier
            ),
            .init(
                node: node.children[1],
                bazelPath: expectedBazelPath + node.children[1],
                specialRootGroupType: specialRootGroupType,
                identifierForBazelPaths: stubbedIdentifier
            ),
            .init(
                node: node.children[2],
                bazelPath: expectedBazelPath + node.children[2],
                specialRootGroupType: specialRootGroupType,
                identifierForBazelPaths: stubbedIdentifier
            ),
            .init(
                node: node.children[3],
                bazelPath: expectedBazelPath + node.children[3],
                specialRootGroupType: specialRootGroupType,
                identifierForBazelPaths: stubbedIdentifier
            ),
        ]
        let stubbedChildResults: [GroupChild.ElementAndChildren] = [
            .init(
                element: .init(
                    name: "weird",
                    object: .init(
                        identifier: "weird identifier",
                        content: "weird content"
                    ),
                    sortOrder: .fileLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "weird identifier",
                        content: "weird content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    (
                        BazelPath("bazel/path/node.xcdatamodeld/weird"),
                        stubbedIdentifier
                    ),
                ],
                knownRegions: ["weird region"],
                resolvedRepositories: [.init(sourcePath: "1", mappedPath: "2")]
            ),
            .init(
                element: .init(
                    name: "a",
                    object: .init(
                        identifier: "a id",
                        content: "a content"
                    ),
                    sortOrder: .fileLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "a id",
                        content: "a content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    (
                        BazelPath("bazel/path/node.xcdatamodeld/a.xcdatamodel"),
                        stubbedIdentifier
                    ),
                ],
                knownRegions: ["enGB"],
                resolvedRepositories: [.init(sourcePath: "3", mappedPath: "4")]
            ),
            .init(
                element: .init(
                    name: "b",
                    object: .init(
                        identifier: "b id",
                        content: "b content"
                    ),
                    sortOrder: .fileLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "b id",
                        content: "b content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    (
                        BazelPath(
                            "bazel/path/node.xcdatamodeld/b.xcdatamodel/odd"
                        ),
                        stubbedIdentifier
                    ),
                    (
                        BazelPath("bazel/path/node.xcdatamodeld/b.xcdatamodel"),
                        stubbedIdentifier
                    ),
                ],
                knownRegions: ["enGB"],
                resolvedRepositories: [.init(sourcePath: "5", mappedPath: "6")]
            ),
            .init(
                element: .init(
                    name: "c",
                    object: .init(
                        identifier: "c id",
                        content: "c content"
                    ),
                    sortOrder: .fileLike
                ),
                transitiveObjects: [
                    .init(
                        identifier: "c id",
                        content: "c content"
                    ),
                ],
                bazelPathAndIdentifiers: [
                    (
                        BazelPath("bazel/path/node.xcdatamodeld/c.xcdatamodel"),
                        stubbedIdentifier
                    ),
                ],
                knownRegions: ["enES"],
                resolvedRepositories: [.init(sourcePath: "7", mappedPath: "8")]
            ),
        ]
        let createFile = ElementCreator.CreateFile.mock(
            groupChildElement: stubbedChildResults
        )

        let expectedSelectedChildIdentifier = "b id"

        let expectedCreateVersionGroupElementCalled: [
            ElementCreator.CreateVersionGroupElement.MockTracker.Called
        ] = [
            .init(
                name: node.name,
                bazelPath: expectedBazelPath,
                specialRootGroupType: specialRootGroupType,
                identifier: stubbedIdentifier,
                childIdentifiers: [
                    stubbedChildResults[0].element.object.identifier,
                    stubbedChildResults[1].element.object.identifier,
                    stubbedChildResults[2].element.object.identifier,
                    stubbedChildResults[3].element.object.identifier,
                ],
                selectedChildIdentifier: expectedSelectedChildIdentifier
            )
        ]
        let stubbedElement = Element(
            name: "stubbed",
            object: .init(
                identifier: stubbedIdentifier,
                content: "content"
            ),
            sortOrder: .groupLike
        )
        let stubbedResolvedRepository = ResolvedRepository(
            sourcePath: "source",
            mappedPath: "mapped"
        )
        let createVersionGroupElement = ElementCreator.CreateVersionGroupElement
            .mock(
                element: stubbedElement,
                resolvedRepository: stubbedResolvedRepository
            )

        let expectedResult = GroupChild.ElementAndChildren(
            element: stubbedElement,
            transitiveObjects: [
                stubbedChildResults[0].transitiveObjects[0],
                stubbedChildResults[1].transitiveObjects[0],
                stubbedChildResults[2].transitiveObjects[0],
                stubbedChildResults[3].transitiveObjects[0],
                stubbedElement.object,
            ],
            bazelPathAndIdentifiers: [
                stubbedChildResults[0].bazelPathAndIdentifiers[0],
                stubbedChildResults[1].bazelPathAndIdentifiers[0],
                stubbedChildResults[2].bazelPathAndIdentifiers[0],
                stubbedChildResults[2].bazelPathAndIdentifiers[1],
                stubbedChildResults[3].bazelPathAndIdentifiers[0],
                (expectedBazelPath, stubbedElement.object.identifier),
            ],
            knownRegions: stubbedChildResults[0].knownRegions
                .union(stubbedChildResults[1].knownRegions)
                .union(stubbedChildResults[2].knownRegions)
                .union(stubbedChildResults[3].knownRegions),
            resolvedRepositories: [
                stubbedChildResults[0].resolvedRepositories[0],
                stubbedChildResults[1].resolvedRepositories[0],
                stubbedChildResults[2].resolvedRepositories[0],
                stubbedChildResults[3].resolvedRepositories[0],
                stubbedResolvedRepository,
            ]
        )

        // Act

        let result = ElementCreator.CreateVersionGroup.defaultCallable(
            for: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: specialRootGroupType,
            createFile: createFile.mock,
            createIdentifier: createIdentifier.mock,
            createVersionGroupElement: createVersionGroupElement.mock,
            selectedModelVersions: selectedModelVersions
        )

        // Assert

        XCTAssertNoDifference(
            createFile.tracker.called,
            expectedCreateFileCalled
        )
        XCTAssertNoDifference(
            createIdentifier.tracker.called,
            expectedCreateIdentifierCalled
        )
        XCTAssertNoDifference(
            createVersionGroupElement.tracker.called,
            expectedCreateVersionGroupElementCalled
        )
        XCTAssertNoDifference(result, expectedResult)
    }
}
