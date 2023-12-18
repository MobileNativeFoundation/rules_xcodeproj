import CustomDump
import OrderedCollections
import XCTest

@testable import pbxtargetdependencies
@testable import PBXProj

final class CreateTargetAttributesObjectsTests: XCTestCase {
    func test_success() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    pbxProjEscapedName: "AB",
                    subIdentifier: .init(shard: "01", hash: "00000000"),
                    full: "AB_ID /* AB */",
                    withoutComment: "AB_ID"
                ),
                dependencies: [
                    "C",
                ]
            ),
            .mock(
                key: ["C"],
                identifier: .init(
                    pbxProjEscapedName: "C",
                    subIdentifier: .init(shard: "00", hash: "12345678"),
                    full: "C_ID /* C */",
                    withoutComment: "C_ID"
                ),
                dependencies: []
            ),
        ]
        let testHosts: [TargetID: TargetID] = [
            "A": "C",
            "B": "C",
        ]
        let identifiedTargetsMap: OrderedDictionary<
            TargetID,
            IdentifiedTarget
        > = [
            "A": identifiedTargets[0],
            "B": identifiedTargets[0],
            "C": identifiedTargets[1],
        ]
        let createdOnToolsVersion = "14.2.1"

        let createTargetAttributesContent =
            Generator.CreateTargetAttributesContent.mock(
                contents: [
                    "{TA_BazelDependnencies}",
                    "{TA_AB}",
                    "{TA_C}",
                ]
            )

        let expectedCreateTargetAttributesContentCalled: [
            Generator.CreateTargetAttributesContent.MockTracker.Called
        ] = [
            .init(
                createdOnToolsVersion: createdOnToolsVersion,
                testHostIdentifierWithoutComment: nil
            ),
            .init(
                createdOnToolsVersion: createdOnToolsVersion,
                testHostIdentifierWithoutComment:
                    identifiedTargetsMap["C"]!.identifier.withoutComment
            ),
            .init(
                createdOnToolsVersion: createdOnToolsVersion,
                testHostIdentifierWithoutComment: nil
            ),
        ]

        let expectedObjects: [Object] = [
            .init(
                identifier: Identifiers.BazelDependencies.id,
                content: "{TA_BazelDependnencies}"
            ),
            .init(
                identifier: identifiedTargetsMap["A"]!.identifier.full,
                content: "{TA_AB}"
            ),
            .init(
                identifier: identifiedTargetsMap["C"]!.identifier.full,
                content: "{TA_C}"
            ),
        ]

        // Act

        let objects = try Generator.CreateTargetAttributesObjects
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiedTargetsMap: identifiedTargetsMap,
                testHosts: testHosts,
                createdOnToolsVersion: createdOnToolsVersion,
                createTargetAttributesContent:
                    createTargetAttributesContent.mock
            )

        // Assert

        XCTAssertNoDifference(
            createTargetAttributesContent.tracker.called,
            expectedCreateTargetAttributesContentCalled
        )
        XCTAssertNoDifference(objects, expectedObjects)
    }

    func test_missingTestHost_throws() {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    pbxProjEscapedName: "AB",
                    subIdentifier: .init(shard: "01", hash: "00000000"),
                    full: "AB_ID /* AB */",
                    withoutComment: "AB_ID"
                ),
                dependencies: [
                    "C",
                ]
            ),
        ]
        let testHosts: [TargetID: TargetID] = [
            "A": "C",
            "B": "C",
        ]
        let identifiedTargetsMap: OrderedDictionary<
            TargetID,
            IdentifiedTarget
        > = [
            "A": identifiedTargets[0],
            "B": identifiedTargets[0],
        ]
        let createdOnToolsVersion = "14.2.1"

        let createTargetAttributesContent =
            Generator.CreateTargetAttributesContent.mock(
                contents: [
                    "{TA_BazelDependnencies}",
                    "{TA_AB}",
                ]
            )

        // Act/Assert

        XCTAssertThrowsError(
            try Generator.CreateTargetAttributesObjects.defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiedTargetsMap: identifiedTargetsMap,
                testHosts: testHosts,
                createdOnToolsVersion: createdOnToolsVersion,
                createTargetAttributesContent:
                    createTargetAttributesContent.mock
            )
        )
    }
}
