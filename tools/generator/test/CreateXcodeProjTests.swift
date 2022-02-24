import CustomDump
import XcodeProj
import XCTest

@testable import generator

final class CreateXcodeProjTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let expectedPBXProj = Fixtures.pbxProj()

        // TODO: Schemes
        let expectedXcodeProj = XcodeProj(
            workspace: XCWorkspace(),
            pbxproj: expectedPBXProj
        )

        // Act

        let xcodeProj = Generator.createXcodeProj(for: pbxProj)

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(xcodeProj, expectedXcodeProj)
    }
}
