import CustomDump
import XCTest

@testable import generator

final class SetTargetDependenciesTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        let consolidatedTargets = Fixtures.consolidatedTargets

        let (pbxTargets, disambiguatedTargets, _) = Fixtures.pbxTargets(
            in: pbxProj,
            consolidatedTargets: consolidatedTargets
        )
        let expectedPBXTargets = Fixtures.pbxTargetsWithDependencies(
            in: expectedPBXProj,
            consolidatedTargets: consolidatedTargets
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
