import CustomDump
import OrderedCollections
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
                originalProductBasename: "B.xctest",
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
                originalProductBasename: "AA.app",
                productBasename: "AA.app",
                identifier: .init(
                    pbxProjEscapedName: "AA escaped",
                    subIdentifier: .init(shard: "07", hash: "11111111"),
                    full: "A_ID /* AA */",
                    withoutComment: "A_ID"
                ),
                // Doesn't make sense, but set just for testing
                watchKitExtension: "W",
                dependencies: ["C"]
            ),
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/1"),
                key: ["C"],
                label: "@//package/path:C",
                productType: .dynamicLibrary,
                name: "C",
                originalProductBasename: "C.dylib",
                productBasename: "C.dylib",
                identifier: .init(
                    pbxProjEscapedName: "C escaped",
                    subIdentifier: .init(shard: "10", hash: "FFFFFFFF"),
                    full: "C_ID /* C */",
                    withoutComment: "C_ID"
                ),
                dependencies: []
            ),
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/2"),
                key: ["W"],
                label: "@//package:W",
                productType: .watch2Extension,
                name: "w",
                originalProductBasename: "W.appex",
                productBasename: "W.appex",
                identifier: .init(
                    pbxProjEscapedName: "WatchKitExtension",
                    subIdentifier: .init(shard: "42", hash: "12345678"),
                    full: "W_ID /* W */",
                    withoutComment: "W_ID"
                ),
                dependencies: []
            ),
        ]
        let identifiedTargetsMap: OrderedDictionary<
            TargetID,
            IdentifiedTarget
        > = [
            "B": identifiedTargets[0],
            "A": identifiedTargets[1],
            "C": identifiedTargets[2],
            "W": identifiedTargets[3],
        ]

        let expectedConsolidationMaps: [URL: [ConsolidationMapEntry]] = [
            URL(fileURLWithPath: "/tmp/1"): [
                .init(
                    key: ["B"],
                    label: "@//:B",
                    productType: .uiTestBundle,
                    name: "b",
                    originalProductBasename: "B.xctest",
                    uiTestHostName: "AA",
                    subIdentifier: .init(shard: "42", hash: "12345678"),
                    watchKitExtensionProductIdentifier: nil,
                    dependencySubIdentifiers: [
                        .bazelDependencies,
                    ]
                ),
                .init(
                    key: ["C"],
                    label: "@//package/path:C",
                    productType: .dynamicLibrary,
                    name: "C",
                    originalProductBasename: "C.dylib",
                    uiTestHostName: nil,
                    subIdentifier: .init(shard: "10", hash: "FFFFFFFF"),
                    watchKitExtensionProductIdentifier: nil,
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
                    originalProductBasename: "AA.app",
                    uiTestHostName: nil,
                    subIdentifier: .init(shard: "07", hash: "11111111"),
                    watchKitExtensionProductIdentifier: .init(
                        shard: "42",
                        type: .product,
                        path: "W.appex",
                        hash: "12345678"
                    ),
                    dependencySubIdentifiers: [
                        .bazelDependencies,
                        .init(shard: "10", hash: "FFFFFFFF"),
                    ]
                ),
            ],
            URL(fileURLWithPath: "/tmp/2"): [
                .init(
                    key: ["W"],
                    label: "@//package:W",
                    productType: .watch2Extension,
                    name: "w",
                    originalProductBasename: "W.appex",
                    uiTestHostName: nil,
                    subIdentifier: .init(shard: "42", hash: "12345678"),
                    watchKitExtensionProductIdentifier: nil,
                    dependencySubIdentifiers: [
                        .bazelDependencies,
                    ]
                ),
            ],
        ]

        // Act

        let consolidationMaps = try Generator.CalculateConsolidationMaps
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiedTargetsMap: identifiedTargetsMap
            )

        // Assert

        XCTAssertNoDifference(consolidationMaps, expectedConsolidationMaps)
    }

    func test_missingDependency_throws() {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(key: ["A"], dependencies: ["B"]),
        ]
        let identifiedTargetsMap: OrderedDictionary<
            TargetID,
            IdentifiedTarget
        > = [
            "A": identifiedTargets[0],
        ]

        // Act/Assert

        XCTAssertThrowsError(
            try Generator.CalculateConsolidationMaps.defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiedTargetsMap: identifiedTargetsMap
            )
        )
    }
}
