import PathKit
import XCTest

@testable import generator

class XcodeProjContainerReferenceTests: XCTestCase {
    func test_CustomStringConvertible() throws {
        let path = Path("path/to/Foo.xcodeproj")
        let containerReference = XcodeProjContainerReference(
            xcodeprojPath: path
        )
        let expected = "container:\(path)"
        XCTAssertEqual("\(containerReference)", expected)
    }

    func test_ExpressibleByStringLiteral() throws {
        XCTFail("IMPLEMENT ME!")
    }
}
