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
        let containerReference: XcodeProjContainerReference =
            "container:path/to/Foo.xcodeproj"
        let expected = XcodeProjContainerReference(
            xcodeprojPath: "path/to/Foo.xcodeproj"
        )
        XCTAssertEqual(containerReference, expected)
    }
}
