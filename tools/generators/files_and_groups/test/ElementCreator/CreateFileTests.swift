import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateFileTests: XCTestCase {
    func test() {
        // Arrange

        let name = "node_name.some_ext"
        let isFolder = false
        let bazelPath: BazelPath = "bazel/path/node_name.some_ext"
        let bazelPathType = BazelPathType.bazelGenerated
        let transitiveBazelPaths: [BazelPath] = [
            "bazel/path/node_name.some_ext/a",
            "bazel/path/node_name.some_ext/b",
        ]

        let expectedCreateFileElementCalled: [
            ElementCreator.CreateFileElement.MockTracker.Called
        ] = [
            .init(
                name: "node_name.some_ext",
                ext: "some_ext",
                bazelPath: "bazel/path/node_name.some_ext",
                bazelPathType: bazelPathType
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
            name: name,
            isFolder: isFolder,
            bazelPath: bazelPath,
            bazelPathType: bazelPathType,
            transitiveBazelPaths: transitiveBazelPaths,
            identifierForBazelPaths: nil,
            createFileElement: createFileElement.mock
        )

        // Assert

        XCTAssertNoDifference(
            createFileElement.tracker.called,
            expectedCreateFileElementCalled
        )
        XCTAssertNoDifference(result, expectedResult)
    }
}
