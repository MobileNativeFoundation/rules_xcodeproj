import CustomDump
import PBXProj
import XCTest

@testable import pbxnativetargets

final class TargetsArgumentsTests: XCTestCase {
    func test_toTargetArguments_emptyFileArrays() throws {
        // Arrange
        let arguments = try TargetsArguments.parse([
            "--targets",
            "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",

            "--xcode-configuration-counts",
            "2",
            "1",
            "1",

            "--xcode-configurations",
            "Debug",
            "Profile",
            "Debug",
            "Profile",

            "--product-types",
            "T",
            "u",
            "L",

            "--package-bin-dirs",
            "applebin_macos-darwin_x86_64-dbg-STABLE-3/bin",
            "applebin_macos-darwin_x86_64-dbg-STABLE-3/bin",
            "macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin",

            "--product-names",
            "generator",
            "tests",
            "generator",

            "--product-basenames",
            "generator_codesigned",
            "tests.xctest",
            "libgenerator.library.a",

            "--module-names",
            "",
            "tests",
            "generator",

            "--platforms",
            "macosx",
            "iphoneos",
            "appletvsimulator",

            "--os-versions",
            "12.0",
            "16.0",
            "9.1",

            "--archs",
            "x86_64",
            "arm64",
            "i386",

            "--build-settings-files",
            "",
            "",
            "/tmp/pbxproj_partials/target_build_settings",

            "--has-c-params",
            "0",
            "0",
            "0",

            "--has-cxx-params",
            "0",
            "0",
            "0",

            "--srcs-counts",
            "0",
            "2",
            "3",

            "--srcs",
            "tools/generators/legacy/test/AddTargetsTests.swift",
            "tools/generators/legacy/test/Array+ExtensionsTests.swift",
            "tools/generators/legacy/src/BuildSettingConditional.swift",
            "tools/generators/legacy/src/DTO/BazelLabel.swift",
            "tools/generators/legacy/src/DTO/BuildSetting.swift",

            "--dsym-paths",
            "",
            "",
            "",
        ])

        let expectedTargetArguments: [TargetID: TargetArguments] = [
            "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3": .init(
                xcodeConfigurations: ["Debug", "Profile"],
                productType: .commandLineTool,
                packageBinDir: "applebin_macos-darwin_x86_64-dbg-STABLE-3/bin",
                productName: "generator",
                productBasename: "generator_codesigned",
                moduleName: "",
                platform: .macOS,
                osVersion: "12.0",
                arch: "x86_64",
                buildSettingsFile: nil,
                hasCParams: false,
                hasCxxParams: false,
                srcs: [],
                nonArcSrcs: [],
                hdrs: [],
                resources: [],
                folderResources: [],
                dSYMPathsBuildSetting: ""
            ),
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3": .init(
                xcodeConfigurations: ["Debug"],
                productType: .unitTestBundle,
                packageBinDir: "applebin_macos-darwin_x86_64-dbg-STABLE-3/bin",
                productName: "tests",
                productBasename: "tests.xctest",
                moduleName: "tests",
                platform: .iOSDevice,
                osVersion: "16.0",
                arch: "arm64",
                buildSettingsFile: nil,
                hasCParams: false,
                hasCxxParams: false,
                srcs: [
                    "tools/generators/legacy/test/AddTargetsTests.swift",
                    "tools/generators/legacy/test/Array+ExtensionsTests.swift",
                ],
                nonArcSrcs: [],
                hdrs: [],
                resources: [],
                folderResources: [],
                dSYMPathsBuildSetting: ""
            ),
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1": .init(
                xcodeConfigurations: ["Profile"],
                productType: .staticLibrary,
                packageBinDir: "macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin",
                productName: "generator",
                productBasename: "libgenerator.library.a",
                moduleName: "generator",
                platform: .tvOSSimulator,
                osVersion: "9.1",
                arch: "i386",
                buildSettingsFile: URL(
                    fileURLWithPath:
                        "/tmp/pbxproj_partials/target_build_settings"
                ),
                hasCParams: false,
                hasCxxParams: false,
                srcs: [
                    "tools/generators/legacy/src/BuildSettingConditional.swift",
                    "tools/generators/legacy/src/DTO/BazelLabel.swift",
                    "tools/generators/legacy/src/DTO/BuildSetting.swift",
                ],
                nonArcSrcs: [],
                hdrs: [],
                resources: [],
                folderResources: [],
                dSYMPathsBuildSetting: ""
            ),
        ]

        // Act

        let targetArguments = arguments.toTargetArguments()

        // Assert

        XCTAssertNoDifference(
            targetArguments,
            expectedTargetArguments
        )
    }

    func test_toTargetArguments_full() throws {
        // Arrange
        let arguments = try TargetsArguments.parse([
            "--targets",
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",

            "--xcode-configuration-counts",
            "1",
            "1",

            "--xcode-configurations",
            "Debug",
            "Debug",

            "--product-types",
            "u",
            "L",

            "--package-bin-dirs",
            "applebin_macos-darwin_x86_64-dbg-STABLE-3/bin",
            "macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin",

            "--product-names",
            "tests",
            "generator",

            "--product-basenames",
            "tests.xctest",
            "libgenerator.library.a",

            "--module-names",
            "tests",
            "generator",

            "--platforms",
            "iphoneos",
            "appletvsimulator",

            "--os-versions",
            "15.0",
            "10.2.1",

            "--archs",
            "arm64",
            "x86_64",

            "--build-settings-files",
            "",
            "/tmp/pbxproj_partials/target_build_settings",

            "--has-c-params",
            "0",
            "1",

            "--has-cxx-params",
            "1",
            "0",

            "--srcs-counts",
            "2",
            "3",

            "--srcs",
            "tools/generators/legacy/test/AddTargetsTests.swift",
            "tools/generators/legacy/test/Array+ExtensionsTests.swift",
            "tools/generators/legacy/src/BuildSettingConditional.swift",
            "tools/generators/legacy/src/DTO/BazelLabel.swift",
            "tools/generators/legacy/src/DTO/BuildSetting.swift",

            "--non-arc-srcs-counts",
            "0",
            "2",

            "--non-arc-srcs",
            "tools/generators/legacy/src/DTO/BazelLabel.m",
            "tools/generators/legacy/src/DTO/BuildSetting.m",

            "--hdrs-counts",
            "2",
            "0",

            "--hdrs",
            "tools/generators/legacy/test/AddTargetsTests.h",
            "tools/generators/legacy/test/Array+ExtensionsTests.h",

            "--resources-counts",
            "1",
            "1",

            "--resources",
            "tools/generators/legacy/test/something.json",
            "tools/generators/legacy/src/something.json",

            "--folder-resources-counts",
            "2",
            "1",

            "--folder-resources",
            "tools/generators/legacy/test/something.bundle",
            "tools/generators/legacy/test/something.framework",
            "tools/generators/legacy/src/something.bundle",

            "--dsym-paths",
            #""bazel-out/applebin_macos-darwin_x86_64-opt-STABLE-4/bin/tools/generator/test/tests.xctest.dSYM" "bazel-out/applebin_macos-darwin_x86_64-opt-STABLE-5/bin/tools/generator/test/tests.xctest.dSYM""#,
            "",
        ])

        let expectedTargetArguments: [TargetID: TargetArguments] = [
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3": .init(
                xcodeConfigurations: ["Debug"],
                productType: .unitTestBundle,
                packageBinDir: "applebin_macos-darwin_x86_64-dbg-STABLE-3/bin",
                productName: "tests",
                productBasename: "tests.xctest",
                moduleName: "tests",
                platform: .iOSDevice,
                osVersion: "15.0",
                arch: "arm64",
                buildSettingsFile: nil,
                hasCParams: false,
                hasCxxParams: true,
                srcs: [
                    "tools/generators/legacy/test/AddTargetsTests.swift",
                    "tools/generators/legacy/test/Array+ExtensionsTests.swift",
                ],
                nonArcSrcs: [],
                hdrs: [
                    "tools/generators/legacy/test/AddTargetsTests.h",
                    "tools/generators/legacy/test/Array+ExtensionsTests.h"
                ],
                resources: [
                    "tools/generators/legacy/test/something.json",
                ],
                folderResources: [
                    BazelPath(
                        "tools/generators/legacy/test/something.bundle",
                        isFolder: true
                    ),
                    BazelPath(
                        "tools/generators/legacy/test/something.framework",
                        isFolder: true
                    ),
                ],
                dSYMPathsBuildSetting: "\"bazel-out/applebin_macos-darwin_x86_64-opt-STABLE-4/bin/tools/generator/test/tests.xctest.dSYM\" \"bazel-out/applebin_macos-darwin_x86_64-opt-STABLE-5/bin/tools/generator/test/tests.xctest.dSYM\""
            ),
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1": .init(
                xcodeConfigurations: ["Debug"],
                productType: .staticLibrary,
                packageBinDir: "macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin",
                productName: "generator",
                productBasename: "libgenerator.library.a",
                moduleName: "generator",
                platform: .tvOSSimulator,
                osVersion: "10.2.1",
                arch: "x86_64",
                buildSettingsFile: URL(
                    fileURLWithPath:
                        "/tmp/pbxproj_partials/target_build_settings"
                ),
                hasCParams: true,
                hasCxxParams: false,
                srcs: [
                    "tools/generators/legacy/src/BuildSettingConditional.swift",
                    "tools/generators/legacy/src/DTO/BazelLabel.swift",
                    "tools/generators/legacy/src/DTO/BuildSetting.swift",
                ],
                nonArcSrcs: [
                    "tools/generators/legacy/src/DTO/BazelLabel.m",
                    "tools/generators/legacy/src/DTO/BuildSetting.m",
                ],
                hdrs: [],
                resources: [
                    "tools/generators/legacy/src/something.json",
                ],
                folderResources: [
                    BazelPath(
                        "tools/generators/legacy/src/something.bundle",
                        isFolder: true
                    ),
                ],
                dSYMPathsBuildSetting: ""
            ),
        ]

        // Act

        let targetArguments = arguments.toTargetArguments()

        // Assert

        XCTAssertNoDifference(targetArguments, expectedTargetArguments)
    }
}
