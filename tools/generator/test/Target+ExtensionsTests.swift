import XCTest

@testable import generator

class TargetExtensionsTests: XCTestCase {
    let target = Target.mock(
        label: "//a:FooBar",
        product: .init(type: .staticLibrary, name: "FooBar", path: "")
    )

    func test_normalizedName() throws {
        XCTAssertEqual(target.normalizedName, "foobar")
    }

    func test_normalizedLabel() throws {
        XCTAssertEqual(target.normalizedLabel, "//a:foobar")
    }
}
