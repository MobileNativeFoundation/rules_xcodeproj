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
    
    func test_topLevel_sortPriority_precedeNonTopLevel() throws {
        XCTAssertTrue(PBXProductType.unitTestBundle.sortOrder < PBXProductType.staticLibrary.sortOrder)
    }
    
    func test_application_sortPriority_precedeTest() throws {
        XCTAssertTrue(PBXProductType.application.sortOrder < PBXProductType.unitTestBundle.sortOrder)
    }
}
