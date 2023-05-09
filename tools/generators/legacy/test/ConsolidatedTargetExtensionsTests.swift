import XCTest

@testable import generator

class ConsolidatedTargetExtensionsTests: XCTestCase {
    let consolidatedTarget = ConsolidatedTarget(
        targets: [
            "id": Target.mock(
                label: "@//a:FooBar",
                product: .init(type: .staticLibrary, name: "FooBar", path: "")
            ),
        ]
    )

    func test_normalizedName() throws {
        XCTAssertEqual(consolidatedTarget.normalizedName, "foobar")
    }

    func test_normalizedLabel() throws {
        XCTAssertEqual(consolidatedTarget.normalizedLabel, "@//a:foobar")
    }
}
