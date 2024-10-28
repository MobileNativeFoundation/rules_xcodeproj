import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateInlineBazelGeneratedConfigGroupTests: XCTestCase {

    func test() {
        let config = PathTreeNode.GeneratedFiles.Config(
            name: "ios-simulator-abc123",
            path: "ios-simulator-abc123/bin",
            children: [
                .file("fileA"),
                .file("fileB"),
            ]
        )

        let fileAElement = Element(name: "fileA", object: .init(identifier: "fileA-identifier", content: ""), sortOrder: .fileLike)
        let fileBElement = Element(name: "fileB", object: .init(identifier: "fileB-identifier", content: ""), sortOrder: .fileLike)
        let expectedBazelParentPath = BazelPath(parent: "bazel-out", path: "ios-simulator-abc123/bin")

        let stubbedGroupChild: [GroupChild] = [
            .elementAndChildren(
                .init(
                    element: fileAElement,
                    transitiveObjects: [],
                    bazelPathAndIdentifiers: [],
                    knownRegions: [],
                    resolvedRepositories: []
                )
            ),
            .elementAndChildren(
                .init(
                    element: fileBElement,
                    transitiveObjects: [],
                    bazelPathAndIdentifiers: [],
                    knownRegions: [],
                    resolvedRepositories: []
                )
            )
        ]

        let expectedCreateGroupChild: [ElementCreator.CreateGroupChild.MockTracker.Called] = [
            .init(
                node: .file("fileA"),
                parentBazelPath: expectedBazelParentPath,
                parentBazelPathType: .bazelGenerated
            ),
            .init(
                node: .file("fileB"),
                parentBazelPath: expectedBazelParentPath,
                parentBazelPathType: .bazelGenerated
            ),

        ]
        let createGroupChild = ElementCreator.CreateGroupChild.mock(children: stubbedGroupChild)


        let expectedGroupChildElements: [ElementCreator.CreateGroupChildElements.MockTracker.Called] = [
            .init(
                parentBazelPath: expectedBazelParentPath,
                groupChildren: stubbedGroupChild,
                resolvedRepositories: []
            )
        ]
        let stubbedCreateGroupChildElement = GroupChildElements(
            elements: [fileAElement, fileBElement],
            transitiveObjects: [],
            bazelPathAndIdentifiers: [],
            knownRegions: [],
            resolvedRepositories: []
        )
        let createGroupChildElements = ElementCreator.CreateGroupChildElements.mock(
            groupChildElements: stubbedCreateGroupChildElement
        )

        let stubbedCreateInlineBazelGeneratedConfigGroupElement = Element(
            name: "ios-simulator-abc123",
            object: .init(
                identifier: "config-simulator-abc123-identifier", content: ""
            ),
            sortOrder: .groupLike
        )
        let createInlineBazelGeneratedConfigGroupElement = ElementCreator.CreateInlineBazelGeneratedConfigGroupElement.mock(
            element: stubbedCreateInlineBazelGeneratedConfigGroupElement
        )
        let expectedCreateInlineBazelGeneratedConfigGroupElement: [ElementCreator.CreateInlineBazelGeneratedConfigGroupElement.MockTracker.Called] = [
            .init(
                name: "ios-simulator-abc123",
                path: "ios-simulator-abc123/bin",
                bazelPath: expectedBazelParentPath,
                childIdentifiers: ["fileA-identifier", "fileB-identifier"]
            )
        ]

        let exepctedResult = GroupChild.ElementAndChildren(
            bazelPath: expectedBazelParentPath,
            element: stubbedCreateInlineBazelGeneratedConfigGroupElement,
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: nil,
            children: stubbedCreateGroupChildElement
        )


        let result = ElementCreator.CreateInlineBazelGeneratedConfigGroup.defaultCallable(
            for: config,
            parentBazelPath: BazelPath("bazel-out"),
            createGroupChild: createGroupChild.mock,
            createGroupChildElements: createGroupChildElements.mock,
            createInlineBazelGeneratedConfigGroupElement: createInlineBazelGeneratedConfigGroupElement.mock
        )

        XCTAssertNoDifference(
            createGroupChild.tracker.called,
            expectedCreateGroupChild
        )

        XCTAssertNoDifference(
            createGroupChildElements.tracker.called,
            expectedGroupChildElements
        )

        XCTAssertNoDifference(
            createInlineBazelGeneratedConfigGroupElement.tracker.called,
            expectedCreateInlineBazelGeneratedConfigGroupElement
        )

        XCTAssertNoDifference(
            result,
            exepctedResult
        )
    }
}
