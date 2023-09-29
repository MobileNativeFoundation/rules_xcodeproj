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
                        .mock(
                            id: "B",
                            label: "@repo//some:AB",
                            productType: .application,
                            productPath: "some/AB.app",
                            productBasename: "AB.app",
                            dependencies: ["C"]
                        ),
                        .mock(
                            id: "A",
                            label: "@repo//some:AB",
                            productType: .application,
                            productPath: "some/AB.app",
                            productBasename: "AB.app",
                            dependencies: ["C"]
                        ),
                    ]
                )
            ),
            .init(
                name: "c (iOS)",
                target: ConsolidatedTarget(
                    ["C"],
                    allTargets: [
                        .mock(
                            id: "C",
                            label: "//:C",
                            productType: .uiTestBundle,
                            productPath: "C.xctest",
                            productBasename: "C.xctest",
                            uiTestHost: "B",
                            // Doesn't make sense, just for testing
                            watchKitExtension: "W"
                        ),
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
            .init(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/A"),
                key: ["A", "B"],
                label: "@repo//some:AB",
                productType: .application,
                name: "AB (macOS)",
                productPath: "some/AB.app",
                productBasename: "AB.app",
                uiTestHostName: nil,
                identifier: .init(
                    pbxProjEscapedName: "AB (macOS)".pbxProjEscaped,
                    subIdentifier: .init(shard: "AB_SHARD", hash: "AB_HASH"),
                    full: "AB_SHARD00AB_HASH000000000001 /* AB (macOS) */",
                    withoutComment: "AB_SHARD00AB_HASH000000000001"
                ),
                watchKitExtension: nil,
                dependencies: [
                    "C",
                ]
            ),
            .init(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/C"),
                key: ["C"],
                label: "//:C",
                productType: .uiTestBundle,
                name: "c (iOS)",
                productPath: "C.xctest",
                productBasename: "C.xctest",
                uiTestHostName: "AB (macOS)",
                identifier: .init(
                    pbxProjEscapedName: "c (iOS)".pbxProjEscaped,
                    subIdentifier: .init(shard: "C_SHARD", hash: "C_HASH"),
                    full: "C_SHARD00C_HASH000000000001 /* c (iOS) */",
                    withoutComment: "C_SHARD00C_HASH000000000001"
                ),
                watchKitExtension: "W",
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
