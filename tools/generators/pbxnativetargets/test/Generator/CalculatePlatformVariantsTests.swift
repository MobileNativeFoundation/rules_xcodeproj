import CustomDump
import ToolCommon
import XCTest

@testable import pbxnativetargets
@testable import PBXProj

class CalculatePlatformVariantsTests: XCTestCase {
    func test_synchronizedFolders_removesSourcesInFolders() throws {
        // Arrange

        let id: TargetID = "//a:A macos-arm64"
        let targetArguments: [TargetID: TargetArguments] = [
            id: .mock(
                srcs: [
                    "a/Other.swift",
                    "a/Sources/A.swift",
                    "a/Sources/Nested/B.swift",
                ],
                nonArcSrcs: [
                    "a/Sources/C.m",
                    "a/D.m",
                ],
                synchronizedFolders: ["a/Sources"]
            ),
        ]

        let expectedConsolidatedInputs = Target.ConsolidatedInputs(
            srcs: ["a/Other.swift"],
            nonArcSrcs: ["a/D.m"],
            synchronizedFolders: ["a/Sources"]
        )

        // Act

        let (_, _, consolidatedInputs) =
            try Generator.CalculatePlatformVariants.defaultCallable(
                ids: [id],
                targetArguments: targetArguments,
                topLevelTargetAttributes: [:],
                unitTestHosts: [:]
            )

        // Assert

        XCTAssertNoDifference(consolidatedInputs, expectedConsolidatedInputs)
    }

    func test_noSynchronizedFolders_keepsSources() throws {
        // Arrange

        let id: TargetID = "//a:A macos-arm64"
        let targetArguments: [TargetID: TargetArguments] = [
            id: .mock(
                srcs: ["a/Sources/A.swift"],
                nonArcSrcs: ["a/Sources/C.m"]
            ),
        ]

        let expectedConsolidatedInputs = Target.ConsolidatedInputs(
            srcs: ["a/Sources/A.swift"],
            nonArcSrcs: ["a/Sources/C.m"]
        )

        // Act

        let (_, _, consolidatedInputs) =
            try Generator.CalculatePlatformVariants.defaultCallable(
                ids: [id],
                targetArguments: targetArguments,
                topLevelTargetAttributes: [:],
                unitTestHosts: [:]
            )

        // Assert

        XCTAssertNoDifference(consolidatedInputs, expectedConsolidatedInputs)
    }
}

private extension TargetArguments {
    static func mock(
        srcs: [BazelPath],
        nonArcSrcs: [BazelPath],
        synchronizedFolders: [BazelPath] = []
    ) -> Self {
        return Self(
            xcodeConfigurations: ["Debug"],
            productType: .staticLibrary,
            packageBinDir: "bazel-out/a",
            productName: "A",
            productBasename: "libA.a",
            moduleName: "A",
            platform: .macOS,
            osVersion: SemanticVersion(version: "13.0")!,
            arch: "arm64",
            buildSettingsFromFile: [],
            hasCParams: false,
            hasCxxParams: false,
            srcs: srcs,
            nonArcSrcs: nonArcSrcs,
            synchronizedFolders: synchronizedFolders,
            dSYMPathsBuildSetting: ""
        )
    }
}
