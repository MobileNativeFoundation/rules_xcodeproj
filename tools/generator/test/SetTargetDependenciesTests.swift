import CustomDump
import XCTest

@testable import generator

final class SetTargetDependenciesTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        let targets = Fixtures.targets

        let (pbxTargets, disambiguatedTargets) = Fixtures.pbxTargets(
            in: pbxProj,
            targets: targets
        )
        let expectedPBXTargets = Fixtures.pbxTargetsWithDependencies(
            in: expectedPBXProj,
            targets: targets
        )

        // Act

        try Generator.setTargetDependencies(
            disambiguatedTargets: disambiguatedTargets,
            pbxTargets: pbxTargets
        )

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(pbxTargets, expectedPBXTargets)
        XCTAssertNoDifference(pbxProj, expectedPBXProj)
    }
}
