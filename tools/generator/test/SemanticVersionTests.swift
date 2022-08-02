import Foundation
import XCTest

@testable import generator

// Inspired by https://gist.github.com/mjdescy/a805b5b4c49ed79fb240d3886815d5a2
public class SemanticVersionNumberTests: XCTestCase {
    func testInitFromStringWhenStringIsMalformedVerionNumberWithMoreThanThreeNumbers() {
        let value = SemanticVersion(version: "1.2.3.4")
        XCTAssertNil(value)
    }

    func testInitFromStringWhenStringIsMalformedVerionNumberWithLessThanThreeNumbers() {
        let value = SemanticVersion(version: "1.2")
        let expected = SemanticVersion(major: 1, minor: 2, patch: 0)
        XCTAssertEqual(value, expected)
    }

    func testInitFromStringWhenStringIsMalformedVerionNumberWithNonNumbers() {
        let value = SemanticVersion(version: "1.2.X")
        XCTAssertNil(value)
    }

    func testInitFromStringWhenStringIsWellFormedVersionNumber() {
        let value = SemanticVersion(version: "1.2.3")
        let expectedValue = SemanticVersion(major: 1, minor: 2, patch: 3)
        XCTAssertEqual(value, expectedValue)
    }

    func testInitFromStringWhenStringIsWellFormedVersionNumberAllZeroes() {
        let value = SemanticVersion(version: "0.0.0")
        let expectedValue = SemanticVersion(major: 0, minor: 0, patch: 0)
        XCTAssertEqual(value, expectedValue)
    }

    func testConvertToString() {
        let sver = SemanticVersion(major: 2, minor: 11, patch: 3)
        let value = String(describing: sver)
        let expectedValue = "2.11.3"
        XCTAssertEqual(value, expectedValue)
    }

    func testEqualityWhenEqual() {
        let lhs = SemanticVersion(major: 2, minor: 11, patch: 3)
        let rhs = SemanticVersion(major: 2, minor: 11, patch: 3)
        XCTAssertEqual(lhs, rhs)
    }

    func testEqualityWhenNotEqual() {
        let lhs = SemanticVersion(major: 2, minor: 11, patch: 3)
        let rhs = SemanticVersion(major: 2, minor: 0, patch: 4)
        XCTAssertNotEqual(lhs, rhs)
    }

    func testComparisonWhenLHSLessThanRHS() {
        let lhs = SemanticVersion(major: 2, minor: 0, patch: 4)
        let rhs = SemanticVersion(major: 2, minor: 11, patch: 3)
        XCTAssertLessThan(lhs, rhs)
    }

    func testComparisonWhenLHSGreaterThanRHS() {
        let lhs = SemanticVersion(major: 2, minor: 11, patch: 3)
        let rhs = SemanticVersion(major: 2, minor: 0, patch: 4)
        XCTAssertGreaterThan(lhs, rhs)
    }
}
