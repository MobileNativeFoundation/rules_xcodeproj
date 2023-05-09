import CustomDump
import PathKit
import XcodeProj
import XCTest

@testable import generator

final class SetTargetConfigurationsTests: XCTestCase {
    private static let directories = Directories(
        workspace: "/Users/TimApple/app",
        projectRoot: "/Users/TimApple",
        executionRoot: "bazel-output-base/execroot/_rules_xcodeproj/build_output_base/execroot/rules_xcodeproj",
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutput: "out/p.xcodeproj"
    )

    func test_integration() async throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        let consolidatedTargets = Fixtures.consolidatedTargets

        let (
            pbxTargets,
            disambiguatedTargets
        ) = Fixtures.pbxTargets(
            in: pbxProj,
            directories: Self.directories,
            consolidatedTargets: consolidatedTargets
        )
        let expectedPBXTargets = Fixtures.pbxTargetsWithConfigurations(
            in: expectedPBXProj,
            directories: Self.directories,
            consolidatedTargets: consolidatedTargets
        )

        // Act

        try await Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            targets: Fixtures.targets,
            buildMode: .xcode,
            minimumXcodeVersion: "13.4.1",
            xcodeConfigurations: ["Profile"],
            defaultXcodeConfiguration: "Profile",
            pbxTargets: pbxTargets,
            hostIDs: Fixtures.project.targetHosts,
            hasBazelDependencies: true
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(pbxTargets, expectedPBXTargets)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }

    func test_sdkroot() async throws {
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

        try await Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            targets: [:],
            buildMode: .xcode,
            minimumXcodeVersion: "13.4.1",
            xcodeConfigurations: ["Profile"],
            defaultXcodeConfiguration: "Profile",
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false
        )

        let sdkRoots: [ConsolidatedTarget.Key: [String: String]] =
            try Self.getBuildSettings(key, from: pbxTargets)

        // Assert

        XCTAssertNoDifference(
            sdkRoots,
            expectedSDKRoots
        )
    }

    func test_supportedPlatforms() async throws {
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

        try await Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            targets: [:],
            buildMode: .xcode,
            minimumXcodeVersion: "13.4.1",
            xcodeConfigurations: ["Profile"],
            defaultXcodeConfiguration: "Profile",
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false
        )

        let supportedPlatforms: [ConsolidatedTarget.Key: [String: String]] =
            try Self.getBuildSettings(key, from: pbxTargets)

        // Assert

        XCTAssertNoDifference(
            supportedPlatforms,
            expectedSupportedPlatforms
        )
    }

    func test_conditionals() async throws {
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

        try await Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            targets: [:],
            buildMode: .xcode,
            minimumXcodeVersion: "13.4.1",
            xcodeConfigurations: ["Profile"],
            defaultXcodeConfiguration: "Profile",
            pbxTargets: pbxTargets,
            hostIDs: [:],
            hasBazelDependencies: false
        )

        var buildSettings: [ConsolidatedTarget.Key: [String: String]] = [:]
        try buildSettings.merge(
            Self.getBuildSettings(targetIDKey, from: pbxTargets)
        ) { old, new in old.merging(new) { _, new in new } }
        try buildSettings.merge(
            Self.getBuildSettings(packageBinDirKey, from: pbxTargets)
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
                        if stringBuildSetting.isEmpty {
                            buildSetting = []
                        } else {
                            buildSetting = [stringBuildSetting]
                        }
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
