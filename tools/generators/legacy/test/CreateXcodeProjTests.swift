import CustomDump
import XcodeProj
import XCTest

@testable import generator

final class CreateXcodeProjTests: XCTestCase {
    func test_basic() throws {
        // Arrange

        let pbxProj = Fixtures.pbxProj()
        let sharedData = Fixtures.xcSharedData()
        let userData = Fixtures.xcUserData()

        let expectedPBXProj = Fixtures.pbxProj()
        let expectedXcodeProj = XcodeProj(
            workspace: XCWorkspace(),
            pbxproj: expectedPBXProj,
            sharedData: sharedData,
            userData: [userData]
        )

        // Act

        let xcodeProj = Generator.createXcodeProj(for: pbxProj, sharedData: sharedData, userData: userData)

        try pbxProj.fixReferences()
        try expectedPBXProj.fixReferences()

        // Assert

        XCTAssertNoDifference(xcodeProj, expectedXcodeProj)
    }
}
