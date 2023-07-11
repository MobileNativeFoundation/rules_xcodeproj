import CustomDump
import XCTest

@testable import pbxproject_targets

final class ConsolidationMapsArgumentsTests: XCTestCase {
    func test_toConsolidationMapArguments() throws {
        // Arrange
        let arguments = try ConsolidationMapsArguments.parse([
            "--consolidation-map-output-paths",
            "/tmp/pbxproj_partials/consolidation_maps/0",
            "/tmp/pbxproj_partials/consolidation_maps/1",

            "--label-counts",
            "2",
            "1",

            "--labels",
            "//tools/generators/legacy:generator",
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle",
            "//tools/generators/legacy:generator.library",

            "--target-counts",
            "1",
            "2",
            "1",

            "--targets",
            "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-4",
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",

            "--xcode-configuration-counts",
            "2",
            "1",
            "1",
            "1",

            "--xcode-configurations",
            "Debug",
            "Release",
            "Debug",
            "Release",
            "Debug",

            "--product-types",
            "com.apple.product-type.tool",
            "com.apple.product-type.bundle.unit-test",
            "com.apple.product-type.bundle.unit-test",
            "com.apple.product-type.library.static",

            "--product-paths",
            "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/generator",
            "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest",
            "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-4/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest",
            "bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin/tools/generators/legacy/libgenerator.library.a",

            "--platforms",
            "iphoneos",
            "macosx",
            "watchos",
            "appletvsimulator",

            "--os-versions",
            "12.0",
            "16.0",
            "16.2.1",
            "9.1",

            "--archs",
            "x86_64",
            "arm64",
            "arm64",
            "i386",

            "--dependency-counts",
            "1",
            "3",
            "3",
            "5",

            "--dependencies",
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
            "//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
            "@com_github_pointfreeco_swift_custom_dump//:CustomDump macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2",
            "//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2",
            "@com_github_pointfreeco_swift_custom_dump//:CustomDump macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2",
            "//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
            "@com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
            "@com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
            "@com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
            "@com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
        ])

        let expectedConsolidationMapArguments: [ConsolidationMapArguments] = [
            .init(
                outputPath: URL(
                    fileURLWithPath: "/tmp/pbxproj_partials/consolidation_maps/0",
                    isDirectory: false
                ),
                targets: [
                    .init(
                        id: "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
                        label: "//tools/generators/legacy:generator",
                        xcodeConfigurations: ["Debug", "Release"],
                        productType: .commandLineTool,
                        productPath: "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/generator",
                        platform: .iOSDevice,
                        osVersion: "12.0",
                        arch: "x86_64",
                        dependencies: [
                            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                        ]
                    ),
                    .init(
                        id: "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
                        label: "//tools/generators/legacy/test:tests.__internal__.__test_bundle",
                        xcodeConfigurations: ["Debug"],
                        productType: .unitTestBundle,
                        productPath: "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest",
                        platform: .macOS,
                        osVersion: "16.0",
                        arch: "arm64",
                        dependencies: [
                            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                            "//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                            "@com_github_pointfreeco_swift_custom_dump//:CustomDump macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                        ]
                    ),
                    .init(
                        id: "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-4",
                        label: "//tools/generators/legacy/test:tests.__internal__.__test_bundle",
                        xcodeConfigurations: ["Release"],
                        productType: .unitTestBundle,
                        productPath: "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-4/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest",
                        platform: .watchOSDevice,
                        osVersion: "16.2.1",
                        arch: "arm64",
                        dependencies: [
                            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2",
                            "//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2",
                            "@com_github_pointfreeco_swift_custom_dump//:CustomDump macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-2",
                        ]
                    ),
                ]
            ),
            .init(
                outputPath: URL(
                    fileURLWithPath: "/tmp/pbxproj_partials/consolidation_maps/1",
                    isDirectory: false
                ),
                targets: [
                    .init(
                        id: "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                        label: "//tools/generators/legacy:generator.library",
                        xcodeConfigurations: ["Debug"],
                        productType: .staticLibrary,
                        productPath: "bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin/tools/generators/legacy/libgenerator.library.a",
                        platform: .tvOSSimulator,
                        osVersion: "9.1",
                        arch: "i386",
                        dependencies: [
                            "//tools/generators/lib/GeneratorCommon:GeneratorCommon macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                            "@com_github_apple_swift_collections//:OrderedCollections macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                            "@com_github_kylef_pathkit//:PathKit macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                            "@com_github_michaeleisel_zippyjson//:ZippyJSON macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                            "@com_github_tuist_xcodeproj//:XcodeProj macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                        ]
                    ),
                ]
            ),
        ]

        // Act

        let consolidationMapArguments = arguments.toConsolidationMapArguments()

        // Assert

        XCTAssertNoDifference(
            consolidationMapArguments,
            expectedConsolidationMapArguments
        )
    }
}
