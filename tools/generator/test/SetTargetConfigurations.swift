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

        let targets = Fixtures.targets

        let (pbxTargets, disambiguatedTargets) = Fixtures.pbxTargets(
            in: pbxProj,
            targets: targets
        )
        let expectedPBXTargets = Fixtures.pbxTargetsWithConfigurations(
            in: expectedPBXProj,
            targets: targets
        )

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            pbxTargets: pbxTargets,
            filePathResolver: Self.filePathResolverFixture
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(pbxTargets, expectedPBXTargets)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }

    private static func createLdRunpathSearchPathsFixtures(
        _ inputs: [(
            os: Platform.OS,
            productType: PBXProductType,
            expectedLdRunpathSearchPaths: [String]?
        )]
    ) -> (
        disambiguatedTargets: [TargetID: DisambiguatedTarget],
        pbxTargets: [TargetID: PBXNativeTarget],
        expectedLdRunpathSearchPaths: [TargetID: [String]?]
    ) {
        var disambiguatedTargets: [TargetID: DisambiguatedTarget] = [:]
        var pbxTargets: [TargetID: PBXNativeTarget] = [:]
        var ldRunpathSearchPaths: [TargetID: [String]?] = [:]
        for input in inputs {
            let id = TargetID("\(input.os)-\(input.productType)")
            disambiguatedTargets[id] = DisambiguatedTarget(
                name: id.rawValue,
                target: Target.mock(
                    platform: .init(
                        os: input.os,
                        arch: "arm64",
                        minimumOsVersion: "11.0",
                        environment: nil
                    ),
                    product: .init(
                        type: input.productType,
                        name: id.rawValue,
                        path: ""
                    )
                )
            )
            pbxTargets[id] = PBXNativeTarget(name: id.rawValue)
            ldRunpathSearchPaths[id] = input.expectedLdRunpathSearchPaths
        }

        return (
            disambiguatedTargets,
            pbxTargets,
            ldRunpathSearchPaths
        )
    }

    func test_ldRunpathSearchPaths() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()

        let (
            disambiguatedTargets,
            pbxTargets,
            expectedLdRunpathSearchPaths
        ) = Self.createLdRunpathSearchPathsFixtures([
            // Applications
            (.macOS, .application, [
                "$(inherited)",
                "@executable_path/../Frameworks",
            ]),
            (.iOS, .application, [
                "$(inherited)",
                "@executable_path/Frameworks",
            ]),
            (.iOS, .onDemandInstallCapableApplication, [
                "$(inherited)",
                "@executable_path/Frameworks",
            ]),
            (.watchOS, .application, [
                "$(inherited)",
                "@executable_path/Frameworks",
            ]),
            (.tvOS, .application, [
                "$(inherited)",
                "@executable_path/Frameworks",
            ]),

            // Frameworks
            (.macOS, .framework, [
                "$(inherited)",
                "@executable_path/../Frameworks",
                "@loader_path/Frameworks",
            ]),
            (.iOS, .framework, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@loader_path/Frameworks",
            ]),
            (.watchOS, .framework, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@loader_path/Frameworks",
            ]),
            (.tvOS, .framework, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@loader_path/Frameworks",
            ]),

            // App Extensions
            (.macOS, .appExtension, [
                "$(inherited)",
                "@executable_path/../Frameworks",
                "@executable_path/../../../../Frameworks",
            ]),
            (.macOS, .xcodeExtension, [
                "$(inherited)",
                "@executable_path/../Frameworks",
                "@executable_path/../../../../Frameworks",
            ]),
            (.iOS, .appExtension, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]),
            (.iOS, .messagesExtension, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]),
            (.iOS, .intentsServiceExtension, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]),

            (.watchOS, .appExtension, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
                "@executable_path/../../../../Frameworks",
            ]),
            (.watchOS, .watchExtension, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]),
            (.watchOS, .watch2Extension, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]),
            (.tvOS, .tvExtension, [
                "$(inherited)",
                "@executable_path/Frameworks",
                "@executable_path/../../Frameworks",
            ]),

            // NOT set
            (.macOS, .commandLineTool, nil),
            (.macOS, .unitTestBundle, nil),
            (.iOS, .uiTestBundle, nil),
            (.watchOS, .watchApp, nil),
            (.watchOS, .watch2App, nil),
            (.iOS, .watch2AppContainer, nil),
            (.tvOS, .staticLibrary, nil),
            (.iOS, .staticFramework, nil),
        ])

        // Act

        try Generator.setTargetConfigurations(
            in: pbxProj,
            for: disambiguatedTargets,
            pbxTargets: pbxTargets,
            filePathResolver: Self.filePathResolverFixture
        )

        var ldRunpathSearchPaths: [TargetID: [String]?] = Dictionary(
            minimumCapacity: expectedLdRunpathSearchPaths.count
        )
        for (id, pbxTarget) in pbxTargets {
            ldRunpathSearchPaths[id] = pbxTarget
                .buildConfigurationList?
                .buildConfigurations
                .first?
                .buildSettings["LD_RUNPATH_SEARCH_PATHS"] as? [String]
        }

        // Assert

        XCTAssertNoDifference(
            ldRunpathSearchPaths,
            expectedLdRunpathSearchPaths
        )
    }
}
