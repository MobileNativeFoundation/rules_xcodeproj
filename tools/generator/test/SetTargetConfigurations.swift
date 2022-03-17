import CustomDump
import PathKit
import XCTest

@testable import generator

final class SetTargetConfigurationsTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        let targets = Fixtures.targets
        let filePathResolver = FilePathResolver(
            externalDirectory: "external",
            generatedDirectory: "bazel-out",
            internalDirectoryName: "rules_xcp",
            workspaceOutputPath: "out/p.xcodeproj"
        )

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
            filePathResolver: filePathResolver
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(pbxTargets, expectedPBXTargets)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
