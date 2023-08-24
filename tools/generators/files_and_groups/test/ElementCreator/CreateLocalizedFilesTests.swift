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

        let expectedCreateLocalizedFileElementCalled: [
            ElementCreator.CreateLocalizedFileElement.MockTracker.Called
        ] = [
            .init(
                name: region,
                path: "en.lproj/z",
                ext: nil,
                bazelPath: "p/en.lproj/z"
            ),
            .init(
                name: region,
                path: "en.lproj/q.ext",
                ext: "ext",
                bazelPath: "p/en.lproj/q.ext"
            ),
        ]
        let stubbedLocalizedFileElements = [
            Element(
                name: "z",
                object: .init(
                    identifier: "z id",
                    content: "z content"
                ),
                sortOrder: .fileLike
            ),
            Element(
                name: "q",
                object: .init(
                    identifier: "q id",
                    content: "q content"
                ),
                sortOrder: .groupLike
            ),
        ]
        let createLocalizedFileElement =
            ElementCreator.CreateLocalizedFileElement.mock(
                elements: stubbedLocalizedFileElements
            )

        let expectedLocalizedFiles: [GroupChild.LocalizedFile] = [
            .init(
                element: stubbedLocalizedFileElements[0],
                region: region,
                name: "z",
                basenameWithoutExt: "z",
                ext: nil,
                bazelPaths: stubbedBazelPaths[0]
            ),
            .init(
                element: stubbedLocalizedFileElements[1],
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
                createLocalizedFileElement: createLocalizedFileElement.mock
            )

        // Assert

        XCTAssertNoDifference(
            collectBazelPaths.tracker.called,
            expectedCollectBazelPathsCalled
        )
        XCTAssertNoDifference(
            createLocalizedFileElement.tracker.called,
            expectedCreateLocalizedFileElementCalled
        )
        XCTAssertNoDifference(
            localizedFiles,
            expectedLocalizedFiles
        )
    }
}
