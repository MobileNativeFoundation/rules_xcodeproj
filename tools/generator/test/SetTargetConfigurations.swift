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
        let externalDirectory: Path = "external"
        let generatedDirectory: Path = "bazel-out"

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
            externalDirectory: externalDirectory,
            generatedDirectory: generatedDirectory
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(pbxTargets, expectedPBXTargets)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
