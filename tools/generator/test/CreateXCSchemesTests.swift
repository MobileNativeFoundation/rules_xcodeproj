import PathKit
import XcodeProj
import XCTest

@testable import generator

class CreateXCSchemesTests: XCTestCase {
    let workspaceOutputPath = Path("examples/foo/Foo.xcodeproj")

    func test_createXCSchemes_WithNoTargets() throws {
        let schemes = try Generator.createXCSchemes(
            workspaceOutputPath: workspaceOutputPath,
            pbxTargets: [:]
        )
        let expected = [XCScheme]()
        XCTAssertEqual(schemes, expected)
    }

    func test_createXCSchemes_WithTargets() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_createXCScheme_LibTarget() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_createXCScheme_LibAndTestTarget() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_createXCScheme_AppTarget() throws {
        XCTFail("IMPLEMENT ME!")
    }
}
