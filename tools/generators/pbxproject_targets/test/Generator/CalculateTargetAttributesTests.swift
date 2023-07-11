import CustomDump
import XCTest

@testable import pbxproject_targets
@testable import PBXProj

final class CalculateTargetAttributesTests: XCTestCase {
    func test_success() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    name: "AB",
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
                    name: "C",
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
        let identifiers: [TargetID : Identifiers.Targets.Identifier] = [
            "A": identifiedTargets[0].identifier,
            "B": identifiedTargets[0].identifier,
            "C": identifiedTargets[1].identifier,
        ]
        let createdOnToolsVersion = "14.2.1"

        let calculateSingleTargetAttributes =
            Generator.CalculateSingleTargetAttributes.mock(
                contents: [
                    "{TA_BazelDependnencies}",
                    "{TA_AB}",
                    "{TA_C}",
                ]
            )

        let expectedCalculateSingleTargetAttributesCalled: [
            Generator.CalculateSingleTargetAttributes.MockTracker.Called
        ] = [
            .init(
                createdOnToolsVersion: createdOnToolsVersion,
                testHostIdentifier: nil
            ),
            .init(
                createdOnToolsVersion: createdOnToolsVersion,
                testHostIdentifier: identifiers["C"]!.full
            ),
            .init(
                createdOnToolsVersion: createdOnToolsVersion,
                testHostIdentifier: nil
            ),
        ]

        let expectedElements: [Element] = [
            .init(
                identifier: Identifiers.BazelDependencies.id,
                content: "{TA_BazelDependnencies}"
            ),
            .init(
                identifier: identifiers["A"]!.full,
                content: "{TA_AB}"
            ),
            .init(
                identifier: identifiers["C"]!.full,
                content: "{TA_C}"
            ),
        ]

        // Act

        let elements = try Generator.CalculateTargetAttributes.defaultCallable(
            identifiedTargets: identifiedTargets,
            testHosts: testHosts,
            identifiers: identifiers,
            createdOnToolsVersion: createdOnToolsVersion,
            calculateSingleTargetAttributes:
                calculateSingleTargetAttributes.mock
        )

        // Assert

        XCTAssertNoDifference(
            calculateSingleTargetAttributes.tracker.called,
            expectedCalculateSingleTargetAttributesCalled
        )
        XCTAssertNoDifference(elements, expectedElements)
    }

    func test_missingTestHost_throws() {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                key: ["A", "B"],
                identifier: .init(
                    name: "AB",
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
        let identifiers: [TargetID : Identifiers.Targets.Identifier] = [
            "A": identifiedTargets[0].identifier,
            "B": identifiedTargets[0].identifier,
        ]
        let createdOnToolsVersion = "14.2.1"

        let calculateSingleTargetAttributes =
            Generator.CalculateSingleTargetAttributes.mock(
                contents: [
                    "{TA_BazelDependnencies}",
                    "{TA_AB}",
                ]
            )

        // Act/Assert

        XCTAssertThrowsError(
            try Generator.CalculateTargetAttributes.defaultCallable(
                identifiedTargets: identifiedTargets,
                testHosts: testHosts,
                identifiers: identifiers,
                createdOnToolsVersion: createdOnToolsVersion,
                calculateSingleTargetAttributes:
                    calculateSingleTargetAttributes.mock
            )
        )
    }
}
