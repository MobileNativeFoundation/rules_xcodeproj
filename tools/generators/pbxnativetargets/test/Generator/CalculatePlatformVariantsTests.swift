import CustomDump
import PBXProj
import XCTest

@testable import pbxnativetargets

final class CalculatePlatformVariantsTests: XCTestCase {
    func test_synchronizedFolders_filterDescendantsFromConsolidatedInputs()
        throws
    {
        let buildableFolder = TargetArguments.BuildableFolder(
            path: "App/Sources",
            includedPaths: ["App/Sources/Feature.swift"],
            excludedPaths: ["App/Sources/Info.plist"]
        )

        let targetArguments: [TargetID: TargetArguments] = [
            "A": .init(
                xcodeConfigurations: ["Debug"],
                productType: .application,
                packageBinDir: "bazel-out/bin/App",
                productName: "App",
                productBasename: "App.app",
                moduleName: "App",
                platform: .iOSDevice,
                osVersion: "18.0",
                arch: "arm64",
                buildSettingsFromFile: [],
                hasCParams: false,
                hasCxxParams: false,
                buildableFolders: [buildableFolder],
                srcs: [
                    "App/Sources/Feature.swift",
                    "App/Other.swift",
                ],
                nonArcSrcs: [
                    "App/Sources/Legacy.m",
                ],
                dSYMPathsBuildSetting: ""
            ),
            "B": .init(
                xcodeConfigurations: ["Debug"],
                productType: .application,
                packageBinDir: "bazel-out/bin/App",
                productName: "App",
                productBasename: "App.app",
                moduleName: "App",
                platform: .iOSDevice,
                osVersion: "18.0",
                arch: "arm64",
                buildSettingsFromFile: [],
                hasCParams: false,
                hasCxxParams: false,
                buildableFolders: [buildableFolder],
                srcs: [
                    "App/Sources/Feature.swift",
                    "App/Other.swift",
                ],
                nonArcSrcs: [
                    "App/Sources/Legacy.m",
                ],
                dSYMPathsBuildSetting: ""
            ),
        ]

        let result = try Generator.CalculatePlatformVariants.defaultCallable(
            ids: ["A", "B"],
            targetArguments: targetArguments,
            topLevelTargetAttributes: [:],
            unitTestHosts: [:]
        )

        XCTAssertNoDifference(
            result.synchronizedFolders,
            [
                .init(
                    path: "App/Sources",
                    includedPaths: ["App/Sources/Feature.swift"],
                    excludedPaths: ["App/Sources/Info.plist"]
                )
            ]
        )
        XCTAssertNoDifference(
            result.consolidatedInputs,
            .init(
                srcs: ["App/Other.swift"],
                nonArcSrcs: []
            )
        )
        XCTAssertNoDifference(result.conditionalFiles, Set<BazelPath>())
        XCTAssertEqual(result.platformVariants.count, 2)
        XCTAssertTrue(result.hasSourceInputs)
    }

    func test_synchronizedFolders_preserveSourcePresenceWhenFilteredInputsAreEmpty()
        throws
    {
        let buildableFolder = TargetArguments.BuildableFolder(
            path: "App",
            includedPaths: ["App/Feature.swift"],
            excludedPaths: []
        )

        let targetArguments: [TargetID: TargetArguments] = [
            "A": .init(
                xcodeConfigurations: ["Debug"],
                productType: .application,
                packageBinDir: "bazel-out/bin/App",
                productName: "App",
                productBasename: "App.app",
                moduleName: "App",
                platform: .iOSDevice,
                osVersion: "18.0",
                arch: "arm64",
                buildSettingsFromFile: [],
                hasCParams: false,
                hasCxxParams: false,
                buildableFolders: [buildableFolder],
                srcs: ["App/Feature.swift"],
                nonArcSrcs: [],
                dSYMPathsBuildSetting: ""
            ),
        ]

        let result = try Generator.CalculatePlatformVariants.defaultCallable(
            ids: ["A"],
            targetArguments: targetArguments,
            topLevelTargetAttributes: [:],
            unitTestHosts: [:]
        )

        XCTAssertTrue(result.hasSourceInputs)
        XCTAssertNoDifference(
            result.consolidatedInputs,
            .init(srcs: [], nonArcSrcs: [])
        )
    }
}
