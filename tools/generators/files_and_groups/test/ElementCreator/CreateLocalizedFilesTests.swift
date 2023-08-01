import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateLocalizedFilesTests: XCTestCase {
    func test() {
        // Arrange

        let node = PathTreeNode(
            name: "en.lproj",
            children: [
                PathTreeNode(name: "z"),
                PathTreeNode(
                    name: "q.ext",
                    children: [PathTreeNode(name: "other")]
                ),
            ]
        )
        let parentBazelPath: BazelPath = "p"
        let specialRootGroupType = SpecialRootGroupType.siblingBazelExternal
        let region = "enGB"

        let expectedCollectBazelPathsCalled: [
            ElementCreator.CollectBazelPaths.MockTracker.Called
        ] = [
            .init(node: node.children[0], bazelPath: "p/en.lproj/z"),
            .init(node: node.children[1], bazelPath: "p/en.lproj/q.ext"),
        ]
        let stubbedBazelPaths: [[BazelPath]] = [
            ["p/en.lproj/z"],
            [
                "p/en.lproj/q.ext/other",
                "p/en.lproj/q.ext",
            ],
        ]
        let collectBazelPaths = ElementCreator.CollectBazelPaths.mock(
            bazelPaths: stubbedBazelPaths
        )

        let expectedCreateFileElementCalled: [
            ElementCreator.CreateFileElement.MockTracker.Called
        ] = [
            .init(
                name: region,
                ext: nil,
                bazelPath: "p/en.lproj/z",
                specialRootGroupType: specialRootGroupType
            ),
            .init(
                name: region,
                ext: "ext",
                bazelPath: "p/en.lproj/q.ext",
                specialRootGroupType: specialRootGroupType
            ),
        ]
        let stubbedCreateFileElementResults = [
            (
                element: Element(
                    name: "z",
                    object: .init(
                        identifier: "z id",
                        content: "z content"
                    ),
                    sortOrder: .fileLike
                ),
                resolvedRepository: ResolvedRepository(
                    sourcePath: "z",
                    mappedPath: "1"
                )
            ),
            (
                element: Element(
                    name: "q",
                    object: .init(
                        identifier: "q id",
                        content: "q content"
                    ),
                    sortOrder: .groupLike
                ),
                resolvedRepository: ResolvedRepository(
                    sourcePath: "y",
                    mappedPath: "2"
                )
            ),
        ]
        let createFileElement = ElementCreator.CreateFileElement.mock(
            results: stubbedCreateFileElementResults
        )

        let expectedLocalizedFiles: [GroupChild.LocalizedFile] = [
            .init(
                element: stubbedCreateFileElementResults[0].element,
                region: region,
                name: "z",
                basenameWithoutExt: "z",
                ext: nil,
                bazelPaths: stubbedBazelPaths[0]
            ),
            .init(
                element: stubbedCreateFileElementResults[1].element,
                region: region,
                name: "q.ext",
                basenameWithoutExt: "q",
                ext: "ext",
                bazelPaths: stubbedBazelPaths[1]
            ),
        ]

        // Act

        let localizedFiles =
            ElementCreator.CreateLocalizedFiles.defaultCallable(
                for: node,
                parentBazelPath: parentBazelPath,
                specialRootGroupType: specialRootGroupType,
                region: region,
                collectBazelPaths: collectBazelPaths.mock,
                createFileElement: createFileElement.mock
            )

        // Assert

        XCTAssertNoDifference(
            collectBazelPaths.tracker.called,
            expectedCollectBazelPathsCalled
        )
        XCTAssertNoDifference(
            createFileElement.tracker.called,
            expectedCreateFileElementCalled
        )
        XCTAssertNoDifference(
            localizedFiles,
            expectedLocalizedFiles
        )
    }
}
