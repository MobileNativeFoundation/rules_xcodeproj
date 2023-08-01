import CustomDump
import XCTest

@testable import pbxtargetdependencies
@testable import PBXProj

final class InnerIdentifyTargetsTests: XCTestCase {
    func test() {
        // Arrange

        let disambiguatedTargets: [DisambiguatedTarget] = [
            .init(
                name: "AB (macOS)",
                target: ConsolidatedTarget(
                    ["B", "A"],
                    allTargets: [
                        .mock(id: "B", dependencies: ["C"]),
                        .mock(id: "A", dependencies: ["C"]),
                    ]
                )
            ),
            .init(
                name: "c (iOS)",
                target: ConsolidatedTarget(
                    ["C"],
                    allTargets: [
                        .mock(id: "C"),
                    ]
                )
            ),
        ]
        let targetIdToConsolidationMapOutputPath: [TargetID : (UInt8, URL)] = [
            "A": (0, URL(fileURLWithPath: "/tmp/A")),
            "B": (1, URL(fileURLWithPath: "/tmp/B")),
            "C": (2, URL(fileURLWithPath: "/tmp/C")),
        ]

        let createTargetSubIdentifier = Generator.CreateTargetSubIdentifier
            .mock(
                subIdentifiers: [
                    .init(shard: "AB_SHARD", hash: "AB_HASH"),
                    .init(shard: "C_SHARD", hash: "C_HASH"),
                ]
            )

        let expectedCreateTargetSubIdentifierCalled: [
            Generator.CreateTargetSubIdentifier.MockTracker.Called
        ] = [
            .init(targetId: "A", shard: 0),
            .init(targetId: "C", shard: 2),
        ]

        let expectedIdentifiedTargets: [IdentifiedTarget] = [
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/A"),
                key: ["A", "B"],
                name: "AB (macOS)",
                identifier: .init(
                    pbxProjEscapedName: "AB (macOS)".pbxProjEscaped,
                    subIdentifier: .init(shard: "AB_SHARD", hash: "AB_HASH"),
                    full: "AB_SHARD00AB_HASH000000000001 /* AB (macOS) */",
                    withoutComment: "AB_SHARD00AB_HASH000000000001"
                ),
                dependencies: [
                    "C",
                ]
            ),
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/C"),
                key: ["C"],
                name: "c (iOS)",
                identifier: .init(
                    pbxProjEscapedName: "c (iOS)".pbxProjEscaped,
                    subIdentifier: .init(shard: "C_SHARD", hash: "C_HASH"),
                    full: "C_SHARD00C_HASH000000000001 /* c (iOS) */",
                    withoutComment: "C_SHARD00C_HASH000000000001"
                ),
                dependencies: []
            ),
        ]

        // Act

        let identifiedTargets = Generator.InnerIdentifyTargets
            .defaultCallable(
                disambiguatedTargets,
                targetIdToConsolidationMapOutputPath:
                    targetIdToConsolidationMapOutputPath,
                createTargetSubIdentifier: createTargetSubIdentifier.mock
            )

        // Assert

        XCTAssertNoDifference(
            createTargetSubIdentifier.tracker.called,
            expectedCreateTargetSubIdentifierCalled
        )
        XCTAssertNoDifference(identifiedTargets, expectedIdentifiedTargets)
    }
}
