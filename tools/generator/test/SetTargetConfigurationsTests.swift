import CustomDump
import PathKit
import XcodeProj
import XCTest

@testable import generator

final class SetTargetConfigurationsTests: XCTestCase {
    private static let filePathResolverFixture = FilePathResolver(
        workspaceDirectory: "/Users/TimApple/app",
        externalDirectory: "/some/bazel14/external",
        bazelOutDirectory: "/some/bazel14/bazel-out",
        internalDirectoryName: "rules_xcp",
        workspaceOutputPath: "out/p.xcodeproj"
    )

    func test_integration() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        let consolidatedTargets = Fixtures.consolidatedTargets

        let (
            pbxTargets,
            disambiguatedTargets,
            xcodeGeneratedFiles,
            bazelRemappedFiles
        ) = Fixtures.pbxTargets(
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
            targets: Fixtures.targets,
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            hostIDs: Fixtures.project.targetHosts,
            hasBazelDependencies: true,
            xcodeGeneratedFiles: xcodeGeneratedFiles,
            bazelRemappedFiles: bazelRemappedFiles,
            filePathResolver: Self.filePathResolverFixture
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(pbxTargets, expectedPBXTargets)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }

    func test_ldRunpathSearchPaths_xcode() throws {
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
                "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__$(ENABLE_PREVIEWS))",
            ]]),
            ([.iOS], .framework, [key: [
                "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__$(ENABLE_PREVIEWS))",
            ]]),
            ([.watchOS], .framework, [key: [
                "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__$(ENABLE_PREVIEWS))",
            ]]),
            ([.tvOS], .framework, [key: [
                "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__$(ENABLE_PREVIEWS))",
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
            targets: [:],
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false,
            xcodeGeneratedFiles: [:],
            bazelRemappedFiles: [:],
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

    func test_ldRunpathSearchPaths_bazel() throws {
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
            targets: [:],
            buildMode: .bazel,
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false,
            xcodeGeneratedFiles: [:],
            bazelRemappedFiles: [:],
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

    func test_previewsLdRunpathSearchPaths_xcode() throws {
        // Arrange

        let key = "PREVIEWS_LD_RUNPATH_SEARCH_PATHS__"
        let pbxProj = Fixtures.pbxProj()

        let (
            disambiguatedTargets,
            pbxTargets,
            expectedPreviewsLdRunpathSearchPaths
        ) = Self.createFixtures([
            ([.macOS], .framework, [
                key: [
                    "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO)",
                ],
                "\(key)NO": [
                    "$(inherited)",
                    "@executable_path/../Frameworks",
                    "@loader_path/Frameworks",
                ],
                "\(key)YES": [
                    "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO)",
                    "$(FRAMEWORK_SEARCH_PATHS)",
                ],
            ]),
            ([.iOS], .framework, [
                key: [
                    "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO)",
                ],
                "\(key)NO": [
                    "$(inherited)",
                    "@executable_path/Frameworks",
                    "@loader_path/Frameworks",
                ],
                "\(key)YES": [
                    "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO)",
                    "$(FRAMEWORK_SEARCH_PATHS)",
                ],
            ]),
            ([.watchOS], .framework, [
                key: [
                    "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO)",
                ],
                "\(key)NO": [
                    "$(inherited)",
                    "@executable_path/Frameworks",
                    "@loader_path/Frameworks",
                ],
                "\(key)YES": [
                    "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO)",
                    "$(FRAMEWORK_SEARCH_PATHS)",
                ],
            ]),
            ([.tvOS], .framework, [
                key: [
                    "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO)",
                ],
                "\(key)NO": [
                    "$(inherited)",
                    "@executable_path/Frameworks",
                    "@loader_path/Frameworks",
                ],
                "\(key)YES": [
                    "$(PREVIEWS_LD_RUNPATH_SEARCH_PATHS__NO)",
                    "$(FRAMEWORK_SEARCH_PATHS)",
                ],
            ]),
        ])

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            targets: [:],
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false,
            xcodeGeneratedFiles: [:],
            bazelRemappedFiles: [:],
            filePathResolver: Self.filePathResolverFixture
        )

        let previewsLdRunpathSearchPaths: [
            ConsolidatedTarget.Key: [String: [String]]
        ] = try Self.getBuildSettings(key, from: pbxTargets)

        // Assert

        XCTAssertNoDifference(
            previewsLdRunpathSearchPaths,
            expectedPreviewsLdRunpathSearchPaths
        )
    }

    func test_previewsLdRunpathSearchPaths_bazel() throws {
        // Arrange

        let key = "PREVIEWS_LD_RUNPATH_SEARCH_PATHS__"
        let pbxProj = Fixtures.pbxProj()

        let (
            disambiguatedTargets,
            pbxTargets,
            expectedPreviewsLdRunpathSearchPaths
        ) = Self.createFixtures([
            ([.macOS], .framework, [String: [String]]()),
            ([.iOS], .framework, [String: [String]]()),
            ([.watchOS], .framework, [String: [String]]()),
            ([.tvOS], .framework, [String: [String]]()),
        ])

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            targets: [:],
            buildMode: .bazel,
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false,
            xcodeGeneratedFiles: [:],
            bazelRemappedFiles: [:],
            filePathResolver: Self.filePathResolverFixture
        )

        let previewsLdRunpathSearchPaths: [
            ConsolidatedTarget.Key: [String: [String]]
        ] = try Self.getBuildSettings(key, from: pbxTargets)

        // Assert

        XCTAssertNoDifference(
            previewsLdRunpathSearchPaths,
            expectedPreviewsLdRunpathSearchPaths
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
            ([.macOS, .iOS, .tvOS, .watchOS], .staticLibrary, [key: "macosx"]),
            ([.macOS, .iOS], .staticLibrary, [key: "macosx"]),
            ([.macOS, .tvOS], .staticLibrary, [key: "macosx"]),
            ([.macOS, .watchOS], .staticLibrary, [key: "macosx"]),
            ([.macOS], .staticLibrary, [key: "macosx"]),

            ([.iOS, .tvOS, .watchOS], .staticLibrary, [key: "iphoneos"]),
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
            targets: [:],
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false,
            xcodeGeneratedFiles: [:],
            bazelRemappedFiles: [:],
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

            ([.iOS, .tvOS, .watchOS], .staticLibrary,
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
            targets: [:],
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false,
            xcodeGeneratedFiles: [:],
            bazelRemappedFiles: [:],
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

        let targetIDKey = "BAZEL_TARGET_ID"
        let packageBinDirKey = "BAZEL_PACKAGE_BIN_DIR"
        let pbxProj = Fixtures.pbxProj()

        let (
            disambiguatedTargets,
            pbxTargets,
            expectedBuildSettings
        ) = Self.createFixtures([
            ([.macOS, .iOS, .tvOS, .watchOS], .staticLibrary,
             [
                targetIDKey: "macOS-staticLibrary",
                "\(targetIDKey)[sdk=iphoneos*]": "iOS-staticLibrary",
                "\(targetIDKey)[sdk=appletvos*]": "tvOS-staticLibrary",
                "\(targetIDKey)[sdk=macosx*]": "$(BAZEL_TARGET_ID)",
                "\(targetIDKey)[sdk=watchos*]": "watchOS-staticLibrary",
                packageBinDirKey: "b/macOS-staticLibrary",
                "\(packageBinDirKey)[sdk=iphoneos*]": "b/iOS-staticLibrary",
                "\(packageBinDirKey)[sdk=appletvos*]": "b/tvOS-staticLibrary",
                "\(packageBinDirKey)[sdk=watchos*]": "b/watchOS-staticLibrary",
             ]),
            ([.macOS, .iOS], .staticLibrary, [
                targetIDKey: "macOS-staticLibrary",
                "\(targetIDKey)[sdk=iphoneos*]": "iOS-staticLibrary",
                "\(targetIDKey)[sdk=macosx*]": "$(BAZEL_TARGET_ID)",
                packageBinDirKey: "b/macOS-staticLibrary",
                "\(packageBinDirKey)[sdk=iphoneos*]": "b/iOS-staticLibrary",
            ]),
            ([.macOS, .tvOS], .staticLibrary, [
                targetIDKey: "macOS-staticLibrary",
                "\(targetIDKey)[sdk=appletvos*]": "tvOS-staticLibrary",
                "\(targetIDKey)[sdk=macosx*]": "$(BAZEL_TARGET_ID)",
                packageBinDirKey: "b/macOS-staticLibrary",
                "\(packageBinDirKey)[sdk=appletvos*]": "b/tvOS-staticLibrary",
            ]),
            ([.macOS, .watchOS], .staticLibrary, [
                targetIDKey: "macOS-staticLibrary",
                "\(targetIDKey)[sdk=watchos*]": "watchOS-staticLibrary",
                "\(targetIDKey)[sdk=macosx*]": "$(BAZEL_TARGET_ID)",
                packageBinDirKey: "b/macOS-staticLibrary",
                "\(packageBinDirKey)[sdk=watchos*]": "b/watchOS-staticLibrary",
            ]),
            ([.macOS], .staticLibrary, [
                targetIDKey: "macOS-staticLibrary",
                "\(targetIDKey)[sdk=macosx*]": "$(BAZEL_TARGET_ID)",
                packageBinDirKey: "b/macOS-staticLibrary",
            ]),

            ([.iOS, .tvOS, .watchOS], .staticLibrary,
             [
                targetIDKey: "iOS-staticLibrary",
                 "\(targetIDKey)[sdk=appletvos*]": "tvOS-staticLibrary",
                "\(targetIDKey)[sdk=iphoneos*]": "$(BAZEL_TARGET_ID)",
                 "\(targetIDKey)[sdk=watchos*]": "watchOS-staticLibrary",
                packageBinDirKey: "b/iOS-staticLibrary",
                 "\(packageBinDirKey)[sdk=appletvos*]": "b/tvOS-staticLibrary",
                 "\(packageBinDirKey)[sdk=watchos*]": "b/watchOS-staticLibrary",
             ]),
            ([.iOS, .tvOS], .staticLibrary, [
                targetIDKey: "iOS-staticLibrary",
                "\(targetIDKey)[sdk=appletvos*]": "tvOS-staticLibrary",
                "\(targetIDKey)[sdk=iphoneos*]": "$(BAZEL_TARGET_ID)",
                packageBinDirKey: "b/iOS-staticLibrary",
                "\(packageBinDirKey)[sdk=appletvos*]": "b/tvOS-staticLibrary",
            ]),
            ([.iOS, .watchOS], .staticLibrary, [
                targetIDKey: "iOS-staticLibrary",
                "\(targetIDKey)[sdk=iphoneos*]": "$(BAZEL_TARGET_ID)",
                "\(targetIDKey)[sdk=watchos*]": "watchOS-staticLibrary",
                packageBinDirKey: "b/iOS-staticLibrary",
                "\(packageBinDirKey)[sdk=watchos*]": "b/watchOS-staticLibrary",
            ]),
            ([.iOS], .staticLibrary, [
                targetIDKey: "iOS-staticLibrary",
                "\(targetIDKey)[sdk=iphoneos*]": "$(BAZEL_TARGET_ID)",
                packageBinDirKey: "b/iOS-staticLibrary",
            ]),

            ([.tvOS, .watchOS], .staticLibrary, [
                targetIDKey: "tvOS-staticLibrary",
                "\(targetIDKey)[sdk=appletvos*]": "$(BAZEL_TARGET_ID)",
                "\(targetIDKey)[sdk=watchos*]": "watchOS-staticLibrary",
                packageBinDirKey: "b/tvOS-staticLibrary",
                "\(packageBinDirKey)[sdk=watchos*]": "b/watchOS-staticLibrary",
            ]),
            ([.tvOS], .staticLibrary, [
                targetIDKey: "tvOS-staticLibrary",
                "\(targetIDKey)[sdk=appletvos*]": "$(BAZEL_TARGET_ID)",
                packageBinDirKey: "b/tvOS-staticLibrary",
            ]),

            ([.watchOS], .staticLibrary, [
                targetIDKey: "watchOS-staticLibrary",
                "\(targetIDKey)[sdk=watchos*]": "$(BAZEL_TARGET_ID)",
                packageBinDirKey: "b/watchOS-staticLibrary",
            ]),
        ])

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            targets: [:],
            buildMode: .xcode,
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false,
            xcodeGeneratedFiles: [:],
            bazelRemappedFiles: [:],
            filePathResolver: Self.filePathResolverFixture
        )

        var buildSettings: [ConsolidatedTarget.Key: [String: String]] = [:]
        buildSettings.merge(
            try Self.getBuildSettings(targetIDKey, from: pbxTargets)
        ) { old, new in old.merging(new) { _, new in new } }
        buildSettings.merge(
            try Self.getBuildSettings(packageBinDirKey, from: pbxTargets)
        ) { old, new in old.merging(new) { _, new in new } }

        // Assert

        XCTAssertNoDifference(
            buildSettings,
            expectedBuildSettings
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

                var variant: Platform.Variant {
                    switch os {
                    case .macOS: return .macOS
                    case .iOS: return .iOSDevice
                    case .tvOS: return .tvOSDevice
                    case .watchOS: return .watchOSDevice
                    }
                }

                let target = Target.mock(
                    packageBinDir: Path("b/\(targetID.rawValue)"),
                    platform: .init(
                        os: os,
                        variant: variant,
                        arch: "arm64",
                        minimumOsVersion: "11.0"
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

    static func getBuildSettings(
        _ keyPrefix: String,
        from pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [ConsolidatedTarget.Key: [String: [String]]] {
        var selectedBuildSettings: [
            ConsolidatedTarget.Key: [String: [String]]
        ] = [:]
        for (key, pbxTarget) in pbxTargets {
            let buildSettings = try XCTUnwrap(
                pbxTarget
                    .buildConfigurationList?
                    .buildConfigurations
                    .first?
                    .buildSettings,
                file: file,
                line: line
            )
            selectedBuildSettings[key] = try buildSettings
                .filter { key, _ in key.hasPrefix(keyPrefix) }
                .mapValues { anyBuildSetting in
                    let buildSetting: [String]
                    if let stringBuildSetting = anyBuildSetting as? String {
                        buildSetting = [stringBuildSetting]
                    } else {
                        buildSetting = try XCTUnwrap(
                            anyBuildSetting as? [String],
                            file: file,
                            line: line
                        )
                    }

                    return buildSetting
                }
        }
        return selectedBuildSettings
    }

    static func getBuildSettings<BuildSettingType>(
        _ keyPrefix: String,
        from pbxTargets: [ConsolidatedTarget.Key: PBXNativeTarget],
        file: StaticString = #filePath,
        line: UInt = #line
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
                    .buildSettings,
                file: file,
                line: line
            )
            selectedBuildSettings[key] = try buildSettings
                .filter { key, _ in key.hasPrefix(keyPrefix) }
                .mapValues { buildSetting in


                    return try XCTUnwrap(
                        buildSetting as? BuildSettingType,
                        """
Build setting value \(buildSetting) had incorrect type
""",
                        file: file,
                        line: line
                    )
                }
        }
        return selectedBuildSettings
    }
}
