import CustomDump
import PBXProj
import XCTest

@testable import files_and_groups

final class CreateVariantGroupTests: XCTestCase {
    func test() {
        // Arrange

        let name = "localized.strings"
        let parentBazelPath: BazelPath = "bazel-out"
        let localizedFiles: [GroupChild.LocalizedFile] = [
            .init(
                element: Element(
                    name: "a",
                    object: .init(
                        identifier: "a id",
                        content: "a content"
                    ),
                    sortOrder: .fileLike
                ),
                region: "enGB",
                name: "a",
                basenameWithoutExt: "a",
                ext: nil,
                bazelPaths: ["bazel-out/enGB/a"]
            ),
            .init(
                element: Element(
                    name: "b",
                    object: .init(
                        identifier: "b id",
                        content: "b content"
                    ),
                    sortOrder: .fileLike
                ),
                region: "frCA",
                name: "b",
                basenameWithoutExt: "b",
                ext: "bundle",
                bazelPaths: [
                    "bazel-out/enGB/b.bundle/other",
                    "bazel-out/enGB/b.bundle",
                ]
            ),
        ]

        let expectedCreateVariantGroupElementCalled: [
            ElementCreator.CreateVariantGroupElement.MockTracker.Called
        ] = [
            .init(
                name: "localized.strings",
                path: "bazel-out/localized.strings",
                childIdentifiers: localizedFiles.map(\.element.object.identifier)
            ),
        ]
        let stubbedElement = Element(
            name: "variant group",
            object: .init(
                identifier: "variant group id",
                content: "variant group content"
            ),
            sortOrder: .fileLike
        )
        let createVariantGroupElement = ElementCreator.CreateVariantGroupElement
            .mock(element: stubbedElement)

        let expectedResult = GroupChild.ElementAndChildren(
            element: stubbedElement,
            transitiveObjects:
                localizedFiles.map(\.element.object) + [stubbedElement.object],
            bazelPathAndIdentifiers: [
                ("bazel-out/enGB/a", stubbedElement.object.identifier),
                (
                    "bazel-out/enGB/b.bundle/other",
                    stubbedElement.object.identifier
                ),
                ("bazel-out/enGB/b.bundle", stubbedElement.object.identifier),
            ],
            knownRegions: ["enGB", "frCA"],
            resolvedRepositories: []
        )

        // Act

        let result = ElementCreator.CreateVariantGroup.defaultCallable(
            name: name,
            parentBazelPath: parentBazelPath,
            localizedFiles: localizedFiles,
            createVariantGroupElement: createVariantGroupElement.mock
        )

        // Assert

        XCTAssertNoDifference(
            createVariantGroupElement.tracker.called,
            expectedCreateVariantGroupElementCalled
        )
        XCTAssertNoDifference(result, expectedResult)
    }
}
