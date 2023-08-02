import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateFileTests: XCTestCase {
    func test() {
        // Arrange

        let node = PathTreeNode(
            name: "node_name.some_ext"
        )
        let bazelPath: BazelPath = "bazel/path/node_name.some_ext"
        let specialRootGroupType = SpecialRootGroupType.bazelGenerated

        let expectedCollectBazelPathsCalled: [
            ElementCreator.CollectBazelPaths.MockTracker.Called
        ] = [
            .init(node: node, bazelPath: "bazel/path/node_name.some_ext"),
        ]
        let stubbedBazelPaths: [BazelPath] = [
            "bazel/path/node_name.some_ext/a",
            "bazel/path/node_name.some_ext/b",
            "bazel/path/node_name.some_ext",
        ]
        let collectBazelPaths = ElementCreator.CollectBazelPaths.mock(
            bazelPaths: [stubbedBazelPaths]
        )

        let expectedCreateFileElementCalled: [
            ElementCreator.CreateFileElement.MockTracker.Called
        ] = [
            .init(
                name: "node_name.some_ext",
                ext: "some_ext",
                bazelPath: "bazel/path/node_name.some_ext",
                specialRootGroupType: specialRootGroupType
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
        let createFileElement = ElementCreator.CreateFileElement.mock(
            results: [
                (
                    element: stubbedElement,
                    resolvedRepository: stubbedResolvedRepository
                ),
            ]
        )

        let expectedResult = GroupChild.ElementAndChildren(
            element: stubbedElement,
            transitiveObjects: [stubbedElement.object],
            bazelPathAndIdentifiers: [
                (
                    "bazel/path/node_name.some_ext/a",
                    stubbedElement.object.identifier
                ),
                (
                    "bazel/path/node_name.some_ext/b",
                    stubbedElement.object.identifier
                ),
                (
                    "bazel/path/node_name.some_ext",
                    stubbedElement.object.identifier
                ),
            ],
            knownRegions: [],
            resolvedRepositories: [stubbedResolvedRepository]
        )

        // Act

        let result = ElementCreator.CreateFile.defaultCallable(
            for: node,
            bazelPath: bazelPath,
            specialRootGroupType: specialRootGroupType,
            identifierForBazelPaths: nil,
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
        XCTAssertNoDifference(result, expectedResult)
    }
}
