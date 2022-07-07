import CustomDump
import PathKit
import XcodeProj
import XCTest

@testable import generator

final class SetTargetConfigurationsTests: XCTestCase {
    private static let filePathResolverFixture = FilePathResolver(
        internalDirectoryName: "rules_xcp",
        workspaceOutputPath: "out/p.xcodeproj"
    )

    func test_integration() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        let consolidatedTargets = Fixtures.consolidatedTargets

        let (pbxTargets, disambiguatedTargets) = Fixtures.pbxTargets(
            in: pbxProj,
            consolidatedTargets: consolidatedTargets
        )
        let expectedPBXTargets = Fixtures.pbxTargetsWithConfigurations(
            in: expectedPBXProj,
            consolidatedTargets: consolidatedTargets
        )

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            filePathResolver: Self.filePathResolverFixture
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(pbxTargets, expectedPBXTargets)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }

    func test_ldRunpathSearchPaths() throws {
        // Arrange

        let key = "LD_RUNPATH_SEARCH_PATHS"
        let pbxProj = Fixtures.pbxProj()

        let (
            disambiguatedTargets,
            pbxTargets,
            expectedLdRunpathSearchPaths
        ) = Self.createFixtures([
            // Applications
            ([.macOS], .application, [key: [
                "$(inherited)",
                "@executable_path/../Frameworks",
            ]]),
            ([.iOS], .application, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
            ]]),
            ([.iOS], .onDemandInstallCapableApplication, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
            ]]),
            ([.watchOS], .application, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
            ]]),
            ([.tvOS], .application, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
            ]]),

            // Frameworks
            ([.macOS], .framework, [key: [
                "$(inherited)",
                "@executable_path/../Frameworks",
                "@loader_path/Frameworks",
            ]]),
            ([.iOS], .framework, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@loader_path/Frameworks",
            ]]),
            ([.watchOS], .framework, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@loader_path/Frameworks",
            ]]),
            ([.tvOS], .framework, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@loader_path/Frameworks",
            ]]),

            // App Extensions
            ([.macOS], .appExtension, [key: [
                "$(inherited)",
                "@executable_path/../Frameworks",
                "@executable_path/../../../../Frameworks",
            ]]),
            ([.macOS], .xcodeExtension, [key: [
                "$(inherited)",
                "@executable_path/../Frameworks",
                "@executable_path/../../../../Frameworks",
            ]]),
            ([.iOS], .appExtension, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]]),
            ([.iOS], .messagesExtension, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]]),
            ([.iOS], .intentsServiceExtension, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]]),

            ([.watchOS], .appExtension, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
                "@executable_path/../../../../Frameworks",
            ]]),
            ([.watchOS], .watchExtension, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]]),
            ([.watchOS], .watch2Extension, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]]),
            ([.tvOS], .tvExtension, [key: [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]]),

            // NOT set
            ([.macOS], .commandLineTool, [:]),
            ([.macOS], .unitTestBundle, [:]),
            ([.iOS], .uiTestBundle, [:]),
            ([.watchOS], .watchApp, [:]),
            ([.watchOS], .watch2App, [:]),
            ([.iOS], .watch2AppContainer, [:]),
            ([.tvOS], .staticLibrary, [:]),
            ([.iOS], .staticFramework, [:]),
        ])

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            filePathResolver: Self.filePathResolverFixture
        )

        let ldRunpathSearchPaths: [ConsolidatedTarget.Key: [String: [String]]] =
            try Self.getBuildSettings(key, from: pbxTargets)

        // Assert

        XCTAssertNoDifference(
            ldRunpathSearchPaths,
            expectedLdRunpathSearchPaths
        )
    }

    func test_sdkroot() throws {
        // Arrange

        let key = "SDKROOT"
        let pbxProj = Fixtures.pbxProj()

        let (
            disambiguatedTargets,
            pbxTargets,
            expectedSDKRoots
        ) = Self.createFixtures([
            ([.macOS, .iOS, .tvOS, .watchOS], .staticLibrary,[key: "macosx"]),
            ([.macOS, .iOS], .staticLibrary, [key: "macosx"]),
            ([.macOS, .tvOS], .staticLibrary, [key: "macosx"]),
            ([.macOS, .watchOS], .staticLibrary, [key: "macosx"]),
            ([.macOS], .staticLibrary, [key: "macosx"]),

            ([.iOS, .tvOS, .watchOS,], .staticLibrary, [key: "iphoneos"]),
            ([.iOS, .tvOS], .staticLibrary, [key: "iphoneos"]),
            ([.iOS, .watchOS], .staticLibrary, [key: "iphoneos"]),
            ([.iOS], .staticLibrary, [key: "iphoneos"]),

            ([.tvOS, .watchOS], .staticLibrary, [key: "appletvos"]),
            ([.tvOS], .staticLibrary, [key: "appletvos"]),

            ([.watchOS], .staticLibrary, [key: "watchos"]),
        ])

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            filePathResolver: Self.filePathResolverFixture
        )

        let sdkRoots: [ConsolidatedTarget.Key: [String: String]] =
            try Self.getBuildSettings(key, from: pbxTargets)

        // Assert

        XCTAssertNoDifference(
            sdkRoots,
            expectedSDKRoots
        )
    }

    func test_supportedPlatforms() throws {
        // Arrange

        let key = "SUPPORTED_PLATFORMS"
        let pbxProj = Fixtures.pbxProj()

        let (
            disambiguatedTargets,
            pbxTargets,
            expectedSupportedPlatforms
        ) = Self.createFixtures([
            ([.macOS, .iOS, .tvOS, .watchOS], .staticLibrary,
             [key: "watchos macosx iphoneos appletvos"]),
            ([.macOS, .iOS], .staticLibrary, [key: "macosx iphoneos"]),
            ([.macOS, .tvOS], .staticLibrary, [key: "macosx appletvos"]),
            ([.macOS, .watchOS], .staticLibrary, [key: "watchos macosx"]),
            ([.macOS], .staticLibrary, [key: "macosx"]),

            ([.iOS, .tvOS, .watchOS,], .staticLibrary,
             [key: "watchos iphoneos appletvos"]),
            ([.iOS, .tvOS], .staticLibrary, [key: "iphoneos appletvos"]),
            ([.iOS, .watchOS], .staticLibrary, [key: "watchos iphoneos"]),
            ([.iOS], .staticLibrary, [key: "iphoneos"]),

            ([.tvOS, .watchOS], .staticLibrary, [key: "watchos appletvos"]),
            ([.tvOS], .staticLibrary, [key: "appletvos"]),

            ([.watchOS], .staticLibrary, [key: "watchos"]),
        ])

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            filePathResolver: Self.filePathResolverFixture
        )

        let supportedPlatforms: [ConsolidatedTarget.Key: [String: String]] =
            try Self.getBuildSettings(key, from: pbxTargets)

        // Assert

        XCTAssertNoDifference(
            supportedPlatforms,
            expectedSupportedPlatforms
        )
    }

    func test_conditionals() throws {
        // Arrange

        let key = "BAZEL_TARGET_ID"
        let pbxProj = Fixtures.pbxProj()

        let (
            disambiguatedTargets,
            pbxTargets,
            expectedSupportedPlatforms
        ) = Self.createFixtures([
            ([.macOS, .iOS, .tvOS, .watchOS], .staticLibrary,
             [
                key: "macOS-staticLibrary",
                "\(key)[sdk=iphoneos*]": "iOS-staticLibrary",
                "\(key)[sdk=appletvos*]": "tvOS-staticLibrary",
                "\(key)[sdk=watchos*]": "watchOS-staticLibrary",
             ]),
            ([.macOS, .iOS], .staticLibrary, [
                key: "macOS-staticLibrary",
                "\(key)[sdk=iphoneos*]": "iOS-staticLibrary",
            ]),
            ([.macOS, .tvOS], .staticLibrary, [
                key: "macOS-staticLibrary",
                "\(key)[sdk=appletvos*]": "tvOS-staticLibrary",
            ]),
            ([.macOS, .watchOS], .staticLibrary, [
                key: "macOS-staticLibrary",
                "\(key)[sdk=watchos*]": "watchOS-staticLibrary",
            ]),
            ([.macOS], .staticLibrary, [
                key: "macOS-staticLibrary",
            ]),

            ([.iOS, .tvOS, .watchOS,], .staticLibrary,
             [
                key: "iOS-staticLibrary",
                "\(key)[sdk=appletvos*]": "tvOS-staticLibrary",
                "\(key)[sdk=watchos*]": "watchOS-staticLibrary",
             ]),
            ([.iOS, .tvOS], .staticLibrary, [
                key: "iOS-staticLibrary",
                "\(key)[sdk=appletvos*]": "tvOS-staticLibrary",
            ]),
            ([.iOS, .watchOS], .staticLibrary, [
                key: "iOS-staticLibrary",
                "\(key)[sdk=watchos*]": "watchOS-staticLibrary",
            ]),
            ([.iOS], .staticLibrary, [
                key: "iOS-staticLibrary",
            ]),

            ([.tvOS, .watchOS], .staticLibrary, [
                key: "tvOS-staticLibrary",
                "\(key)[sdk=watchos*]": "watchOS-staticLibrary",
            ]),
            ([.tvOS], .staticLibrary, [
                key: "tvOS-staticLibrary",
            ]),

            ([.watchOS], .staticLibrary, [
                key: "watchOS-staticLibrary",
            ]),
        ])

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            filePathResolver: Self.filePathResolverFixture
        )

        let supportedPlatforms: [ConsolidatedTarget.Key: [String: String]] =
            try Self.getBuildSettings(key, from: pbxTargets)

        // Assert

        XCTAssertNoDifference(
            supportedPlatforms,
            expectedSupportedPlatforms
        )
    }

    private static func createFixtures<BuildSettingType>(
        _ inputs: [(
            oses: Set<Platform.OS>,
            productType: PBXProductType,
            expectedBuildSettings: [String: BuildSettingType]
        )]
    ) -> (
        disambiguatedTargets: DisambiguatedTargets,
        pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget],
        buildSettings: [ConsolidatedTarget.Key: [String: BuildSettingType]]
    ) {
        var keys: [TargetID: ConsolidatedTarget.Key] = [:]
        var consolidatedTargets: [ConsolidatedTarget.Key: DisambiguatedTarget] =
            [:]
        var pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget] = [:]
        var buildSettings: [ConsolidatedTarget.Key: [String: BuildSettingType]]
            = [:]
        for input in inputs {
            var targets: [TargetID: Target] = [:]
            for os in input.oses {
                let targetID = TargetID("\(os)-\(input.productType)")

                var platformName: String {
                    switch os {
                    case .macOS: return "macosx"
                    case .iOS: return "iphoneos"
                    case .tvOS: return "appletvos"
                    case .watchOS: return "watchos"
                    }
                }

                let target = Target.mock(
                    platform:  .init(
                        name: platformName,
                        os: os,
                        arch: "arm64",
                        minimumOsVersion: "11.0",
                        environment: nil
                    ),
                    product: .init(
                        type: input.productType,
                        name: input.productType.prettyName,
                        path: ""
                    )
                )
                targets[targetID] = target
            }

            let key = ConsolidatedTarget.Key(Set(targets.keys))
            for id in targets.keys {
                keys[id] = key
            }

            let target = ConsolidatedTarget(targets: targets)

            consolidatedTargets[key] = DisambiguatedTarget(
                name: target.name,
                target: target
            )
            pbxTargets[key] = PBXNativeTarget(name: target.name)
            buildSettings[key] = input.expectedBuildSettings
        }

        return (
            DisambiguatedTargets(
                keys: keys,
                targets: consolidatedTargets
            ),
            pbxTargets,
            buildSettings
        )
    }

    static func getBuildSettings<BuildSettingType>(
        _ keyPrefix: String,
        from pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget]
    ) throws -> [ConsolidatedTarget.Key: [String: BuildSettingType]] {
        var selectedBuildSettings: [
            ConsolidatedTarget.Key: [String: BuildSettingType]
        ] = [:]
        for (key, pbxTarget) in pbxTargets {
            let buildSettings = try XCTUnwrap(
                pbxTarget
                    .buildConfigurationList?
                    .buildConfigurations
                    .first?
                    .buildSettings
            )
            selectedBuildSettings[key] = try buildSettings
                .filter { key, _ in key.starts(with: keyPrefix) }
                .mapValues { buildSetting in
                    try XCTUnwrap(buildSetting as? BuildSettingType)
                }
        }
        return selectedBuildSettings
    }
}

