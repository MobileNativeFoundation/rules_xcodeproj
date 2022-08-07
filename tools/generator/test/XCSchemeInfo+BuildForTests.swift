import XCTest

@testable import generator

// MARK: `xcSchemeValue` Tests

extension XCSchemeInfoBuildForTests {
    func test_xcSchemeValue() throws {
        XCTAssertNil(XCSchemeInfo.BuildFor.Value.disabled.xcSchemeValue(.running))
        XCTAssertEqual(XCSchemeInfo.BuildFor.Value.unspecified.xcSchemeValue(.running), .running)
        XCTAssertEqual(XCSchemeInfo.BuildFor.Value.enabled.xcSchemeValue(.running), .running)
    }
}

// MARK: Test Data

class XCSchemeInfoBuildForTests: XCTestCase {}
