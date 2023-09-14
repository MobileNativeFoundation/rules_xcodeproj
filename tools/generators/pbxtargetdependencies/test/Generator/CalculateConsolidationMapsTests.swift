import CustomDump
import XCTest

@testable import pbxtargetdependencies
@testable import PBXProj

final class CalculateConsolidationMapsTests: XCTestCase {
    func test_success() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/1"),
                key: ["B"],
                label: "@//:B",
                productType: .uiTestBundle,
                name: "b",
                productPath: "B.xctest",
                productBasename: "B.xctest",
                uiTestHostName: "AA",
                identifier: .init(
                    pbxProjEscapedName: "b escaped",
                    subIdentifier: .init(shard: "42", hash: "12345678"),
                    full: "B_ID /* b */",
                    withoutComment: "B_ID"
                ),
                dependencies: []
            ),
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/0"),
                key: ["A"],
                label: "@repo//:A",
                productType: .application,
                name: "AA",
                productPath: "an/AA.app",
                productBasename: "AA.app",
                identifier: .init(
                    pbxProjEscapedName: "AA escaped",
                    subIdentifier: .init(shard: "07", hash: "11111111"),
                    full: "A_ID /* AA */",
                    withoutComment: "A_ID"
                ),
                dependencies: ["C"]
            ),
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/1"),
                key: ["C"],
                label: "@//package/path:C",
                productType: .dynamicLibrary,
                name: "C",
                productPath: "some/C.dylib",
                productBasename: "C.dylib",
                identifier: .init(
                    pbxProjEscapedName: "C escaped",
                    subIdentifier: .init(shard: "10", hash: "FFFFFFFF"),
                    full: "C_ID /* C */",
                    withoutComment: "C_ID"
                ),
                dependencies: []
            ),
        ]
        let identifiers: [TargetID: Identifiers.Targets.Identifier] = [
            "A": identifiedTargets[1].identifier,
            "B": identifiedTargets[0].identifier,
            "C": identifiedTargets[2].identifier,
        ]

        let expectedConsolidationMaps: [URL: [ConsolidationMapEntry]] = [
            URL(fileURLWithPath: "/tmp/1"): [
                .init(
                    key: ["B"],
                    label: "@//:B",
                    productType: .uiTestBundle,
                    name: "b",
                    productPath: "B.xctest",
                    uiTestHostName: "AA",
                    subIdentifier: .init(shard: "42", hash: "12345678"),
                    dependencySubIdentifiers: [
                        .bazelDependencies,
                    ]
                ),
                .init(
                    key: ["C"],
                    label: "@//package/path:C",
                    productType: .dynamicLibrary,
                    name: "C",
                    productPath: "some/C.dylib",
                    uiTestHostName: nil,
                    subIdentifier: .init(shard: "10", hash: "FFFFFFFF"),
                    dependencySubIdentifiers: [
                        .bazelDependencies,
                    ]
                ),
            ],
            URL(fileURLWithPath: "/tmp/0"): [
                .init(
                    key: ["A"],
                    label: "@repo//:A",
                    productType: .application,
                    name: "AA",
                    productPath: "an/AA.app",
                    uiTestHostName: nil,
                    subIdentifier: .init(shard: "07", hash: "11111111"),
                    dependencySubIdentifiers: [
                        .bazelDependencies,
                        .init(shard: "10", hash: "FFFFFFFF"),
                    ]
                ),
            ],
        ]

        // Act

        let consolidationMaps = try Generator.CalculateConsolidationMaps
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiers: identifiers
            )

        // Assert

        XCTAssertNoDifference(consolidationMaps, expectedConsolidationMaps)
    }

    func test_missingDependency_throws() {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(key: ["A"], dependencies: ["B"]),
        ]
        let identifiers: [TargetID: Identifiers.Targets.Identifier] = [
            "A": identifiedTargets[0].identifier,
        ]

        // Act/Assert

        XCTAssertThrowsError(
            try Generator.CalculateConsolidationMaps.defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiers: identifiers
            )
        )
    }
}
