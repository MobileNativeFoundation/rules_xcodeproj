import XcodeProj
import XCTest

@testable import generator

class PBXProductTypeExtensionsTests: XCTestCase {
    func test_isTopLevel_whenIsCommandLine() throws {
        XCTAssertTrue(PBXProductType.commandLineTool.isTopLevel)
    }

    func test_isTopLevel_whenIsApplication() throws {
        XCTAssertTrue(PBXProductType.application.isTopLevel)
    }

    func test_isTopLevel_whenIsTestBundle() throws {
        XCTAssertTrue(PBXProductType.unitTestBundle.isTopLevel)
    }

    func test_isTopLevel_whenIsNotTopLevel() throws {
        XCTAssertFalse(PBXProductType.staticLibrary.isTopLevel)
    }
}
