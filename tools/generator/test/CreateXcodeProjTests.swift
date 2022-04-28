import CustomDump
import XcodeProj
import XCTest

@testable import generator

final class CreateXcodeProjTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let sharedData = Fixtures.xcSharedData()

        let expectedPBXProj = Fixtures.pbxProj()
        let expectedXcodeProj = XcodeProj(
            workspace: XCWorkspace(),
            pbxproj: expectedPBXProj,
            sharedData: sharedData
        )

        // Act

        let xcodeProj = Generator.createXcodeProj(for: pbxProj, sharedData: sharedData)

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(xcodeProj, expectedXcodeProj)
    }
}
