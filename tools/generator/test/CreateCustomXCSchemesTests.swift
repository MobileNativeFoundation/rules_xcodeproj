import XCTest

@testable import generator

extension CreateCustomXCSchemesTests {
    func test_createCustomXCSchemes_noCustomSchemes() throws {
        XCTFail("IMPLEMENT ME!")
    }

    func test_createCustomXCSchemes_withCustomSchemes() throws {
        XCTFail("IMPLEMENT ME!")
    }
}

class CreateCustomXCSchemesTests: XCTestCase {
    let filePathResolver = FilePathResolver(
        internalDirectoryName: "rules_xcodeproj",
        workspaceOutputPath: "examples/foo/Foo.xcodeproj"
    )

    lazy var targetResolver = Fixtures.targetResolver(
        referencedContainer: filePathResolver.containerReference
    )
}
